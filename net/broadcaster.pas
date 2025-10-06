{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/net/broadcaster.go
}
unit V.Net.Broadcaster;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  V.Interfaces.Core, V.Net.Peer, V.Net.Interface, V.Common.Types, V.Log15,
  V.Common.Bloom, V.Tools.Circle;

type
  IBlockStore = interface
    ['{A1B2C3D4-E5F6-4A8B-9C8D-7E6F5A4B3C2D}']
    procedure EnqueueAccountBlock(Block: PAccountBlock);
    function DequeueAccountBlock: PAccountBlock;
    procedure EnqueueSnapshotBlock(Block: PSnapshotBlock);
    function DequeueSnapshotBlock: PSnapshotBlock;
  end;

  IForwardStrategy = interface
    ['{B2C3D4E5-F6A7-4B8C-AD9E-8F706B5C4D3E}']
    function ChoosePeers(Sender: TPeer): TArray<TPeer>;
  end;

  IBroadChainReader = interface
    ['{C3D4E5F6-A7B8-4C9D-BEAF-90817C6D5E4F}']
    function GetLatestSnapshotBlock: PSnapshotBlock;
    function GetConfirmedTimes(const BlockHash: THash): UInt64;
  end;

  TBroadcaster = class(TInterfacedObject, IMsgHandler, IBroadcaster)
  private
    FPeers: TPeerSet;
    FStrategy: IForwardStrategy;
    FState: TSyncState;
    FVerifier: IVerifier;
    FFeed: IBlockSubscriber;
    FFilter: TFilter;
    FRings: TObject; // Placeholder for TRingStatic
    FStore: IBlockStore;
    FStatistic: TList;
    FChain: IBroadChainReader;
    FLog: TLogger;
  public
    constructor Create(APeers: TPeerSet; AVerifier: IVerifier; AFeed: IBlockSubscriber; AStore: IBlockStore; AStrategy: IForwardStrategy; AChain: IBroadChainReader);
    destructor Destroy; override;
    // IMsgHandler
    procedure Handle(const Msg: TMsg);
    // IBroadcaster
    procedure BroadcastSnapshotBlock(Block: PSnapshotBlock);
    procedure BroadcastSnapshotBlocks(const Blocks: TSnapshotChunkArray);
    procedure BroadcastAccountBlock(Block: PAccountBlock);
    procedure BroadcastAccountBlocks(const Blocks: TAccountBlockArray);
  end;

implementation

uses System.Threading, V.Monitor;

type
  TMemBlockStore = class(TInterfacedObject, IBlockStore)
  private
    FCritSect: TCriticalSection;
    FAccountBlocks: TQueue<PAccountBlock>;
    FSnapshotBlocks: TQueue<PSnapshotBlock>;
  public
    constructor Create(MaxSize: Integer);
    destructor Destroy; override;
    procedure EnqueueAccountBlock(Block: PAccountBlock);
    function DequeueAccountBlock: PAccountBlock;
    procedure EnqueueSnapshotBlock(Block: PSnapshotBlock);
    function DequeueSnapshotBlock: PSnapshotBlock;
  end;

{ TMemBlockStore }
constructor TMemBlockStore.Create(MaxSize: Integer);
begin
  inherited Create;
  FCritSect := TCriticalSection.Create;
  FAccountBlocks := TQueue<PAccountBlock>.Create;
  FSnapshotBlocks := TQueue<PSnapshotBlock>.Create;
end;
destructor TMemBlockStore.Destroy;
begin
  FCritSect.Free;
  FAccountBlocks.Free;
  FSnapshotBlocks.Free;
  inherited Destroy;
end;
procedure TMemBlockStore.EnqueueAccountBlock(Block: PAccountBlock);
begin
  FCritSect.Enter;
  try
    FAccountBlocks.Enqueue(Block);
  finally
    FCritSect.Leave;
  end;
end;
function TMemBlockStore.DequeueAccountBlock: PAccountBlock;
begin
  FCritSect.Enter;
  try
    if FAccountBlocks.Count > 0 then
      Result := FAccountBlocks.Dequeue
    else
      Result := nil;
  finally
    FCritSect.Leave;
  end;
end;
procedure TMemBlockStore.EnqueueSnapshotBlock(Block: PSnapshotBlock);
begin
  FCritSect.Enter;
  try
    FSnapshotBlocks.Enqueue(Block);
  finally
    FCritSect.Leave;
  end;
end;
function TMemBlockStore.DequeueSnapshotBlock: PSnapshotBlock;
begin
  FCritSect.Enter;
  try
    if FSnapshotBlocks.Count > 0 then
      Result := FSnapshotBlocks.Dequeue
    else
      Result := nil;
  finally
    FCritSect.Leave;
  end;
end;


{ TBroadcaster }

constructor TBroadcaster.Create(APeers: TPeerSet; AVerifier: IVerifier; AFeed: IBlockSubscriber; AStore: IBlockStore; AStrategy: IForwardStrategy; AChain: IBroadChainReader);
begin
  inherited Create;
  FPeers := APeers;
  FVerifier := AVerifier;
  FFeed := AFeed;
  FStore := AStore;
  FStrategy := AStrategy;
  FChain := AChain;
  FStatistic := TList.Create(1000); // Example size
  FFilter := TFilter.Create(100000, 0.0001);
  FLog := V.Log15.GLog;
end;

destructor TBroadcaster.Destroy;
begin
  FStatistic.Free;
  FFilter.Free;
  inherited Destroy;
end;

procedure TBroadcaster.Handle(const Msg: TMsg);
var
  startTime: TDateTime;
  nb: TNewSnapshotBlock;
  block: PSnapshotBlock;
  hash: THash;
begin
  startTime := Now;
  try
    case Msg.Code of
      CodeNewSnapshotBlock:
        begin
          nb := TNewSnapshotBlock.Create;
          nb.Deserialize(Msg.Payload);
          if nb.Block = nil then
            raise Exception.Create('Missing broadcast block');
          block := nb.Block;
          if FFilter.Test(block.Hash) then Exit;
          // In a real implementation, you would compute the hash
          // hash := block.ComputeHash;
          if FFilter.TestAndAdd(hash) then Exit;
          FVerifier.VerifyNetSnapshotBlock(block);
          // Forwarding logic here...
          if FState = ssSynced then
            FFeed.SubscribeSnapshotBlock(procedure(B: PSnapshotBlock; S: TBlockSource) begin end) // Simplified
          else
            FStore.EnqueueSnapshotBlock(block);
        end;
      CodeNewAccountBlock:
        begin
          // Similar logic for account blocks
        end;
    end;
  finally
    V.Monitor.LogTime('broadcast', 'handle', startTime);
  end;
end;

procedure TBroadcaster.BroadcastSnapshotBlock(Block: PSnapshotBlock);
var
  msg: TNewSnapshotBlock;
  data: TBytes;
  rawMsg: TMsg;
  peers: TArray<TPeer>;
  p: TPeer;
begin
  if FState = ssSyncing then Exit;
  msg := TNewSnapshotBlock.Create;
  msg.Block := Block;
  msg.TTL := 32;
  data := msg.Serialize;
  FFilter.Add(Block.Hash);
  rawMsg.Code := CodeNewSnapshotBlock;
  rawMsg.Payload := data;
  peers := FPeers.AllPeers;
  for p in peers do
    p.WriteMsg(rawMsg);
end;
procedure TBroadcaster.BroadcastSnapshotBlocks(const Blocks: TSnapshotChunkArray); begin end;
procedure TBroadcaster.BroadcastAccountBlock(Block: PAccountBlock); begin end;
procedure TBroadcaster.BroadcastAccountBlocks(const Blocks: TAccountBlockArray); begin end;

end.