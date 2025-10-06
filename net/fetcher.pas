{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/net/fetcher.go
}
unit V.Net.Fetcher;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  V.Common.Types, V.Interfaces.Core, V.Net.Message, V.Net.Peer, V.Log15;

type
  TReqState = (rsWaiting, rsPending, rsDone, rsError);

  IBlockReceiver = interface
    ['{A1B2C3D4-E5F6-4A8B-9C8D-7E6F5A4B3C2D}']
    procedure ReceiveSnapshotBlock(Block: PSnapshotBlock; Source: TBlockSource);
    procedure ReceiveAccountBlock(Block: PAccountBlock; Source: TBlockSource);
  end;

  TFetchCallback = procedure(Msg: TMsg; Err: Exception);

  TPeerFetchResult = record
    Status: TReqState;
    T: Int64;
  end;

  TFetchRecord = class
  public
    Id: TMsgId;
    Hash: THash;
    AddAt: Int64;
    T: Int64;
    Mark: Integer;
    St: TReqState;
    Targets: TDictionary<TNodeID, PPeerFetchResult>;
    Callback: TFetchCallback;
    procedure Reset;
  end;

  TFetcher = class(TInterfacedObject, IMsgHandler, IFetcher)
  private
    FIdGen: TMsgId;
    FRecordsById: TDictionary<TMsgId, TFetchRecord>;
    FRecordsByHash: TDictionary<THash, TFetchRecord>;
    FCritSect: TCriticalSection;
    FPool: TObjectPool<TFetchRecord>;
    FPeerFetchResultPool: TObjectPool<PPeerFetchResult>;
    FPeers: TPeerSet;
    FState: TSyncState;
    FReceiver: IBlockReceiver;
    FLog: TLogger;
    FBlackBlocks: TDictionary<THash, Boolean>;
    FSbp: Boolean;
    FTerm: TEvent;
    FCleanThread: TThread;
    procedure CleanLoop;
    procedure Done(Id: TMsgId; Peer: TPeer; Msg: TMsg; Err: Exception);
  public
    constructor Create(APeers: TPeerSet; AReceiver: IBlockReceiver; ABlackBlocks: TDictionary<THash, Boolean>);
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    // IMsgHandler
    procedure Handle(const Msg: TMsg);
    // IFetcher
    procedure FetchSnapshotBlocks(const Start: THash; Count: UInt64);
    procedure FetchSnapshotBlocksWithHeight(const Hash: THash; Height, Count: UInt64);
    procedure FetchAccountBlocks(const Start: THash; Count: UInt64; Address: PAddress);
    procedure FetchAccountBlocksWithHeight(const Start: THash; Count: UInt64; Address: PAddress; SHeight: UInt64);
  end;

implementation

uses System.Threading, V.Net.VNode;

{ TFetchRecord }

procedure TFetchRecord.Reset;
begin
  Mark := 0;
  Targets.Clear;
  Callback := nil;
end;

{ TFetcher }

constructor TFetcher.Create(APeers: TPeerSet; AReceiver: IBlockReceiver; ABlackBlocks: TDictionary<THash, Boolean>);
begin
  inherited Create;
  FPeers := APeers;
  FReceiver := AReceiver;
  FBlackBlocks := ABlackBlocks;
  FRecordsById := TDictionary<TMsgId, TFetchRecord>.Create;
  FRecordsByHash := TDictionary<THash, TFetchRecord>.Create;
  FCritSect := TCriticalSection.Create;
  FPool := TObjectPool<TFetchRecord>.Create;
  FPeerFetchResultPool := TObjectPool<PPeerFetchResult>.Create;
  FLog := V.Log15.GLog;
end;

destructor TFetcher.Destroy;
begin
  Stop;
  FRecordsById.Free;
  FRecordsByHash.Free;
  FCritSect.Free;
  FPool.Free;
  FPeerFetchResultPool.Free;
  inherited Destroy;
end;

procedure TFetcher.Start;
begin
  FTerm := TEvent.Create(nil, True, False, '');
  FCleanThread := TThread.CreateAnonymousThread(CleanLoop);
  FCleanThread.Start;
end;

procedure TFetcher.Stop;
begin
  if Assigned(FTerm) then
    FTerm.SetEvent;
  if Assigned(FCleanThread) then
  begin
    FCleanThread.WaitFor;
    FCleanThread := nil;
  end;
  if Assigned(FTerm) then
  begin
    FTerm.Free;
    FTerm := nil;
  end;
end;

procedure TFetcher.CleanLoop;
begin
  while not FTerm.WaitFor(4000) do
  begin
    // Cleaning logic here
  end;
end;

procedure TFetcher.Handle(const Msg: TMsg);
var
  bs: TSnapshotBlocks;
  ab: TAccountBlocks;
  block: PSnapshotBlock;
  ablock: PAccountBlock;
begin
  case Msg.Code of
    CodeSnapshotBlocks:
      begin
        bs := TSnapshotBlocks.Create;
        bs.Deserialize(Msg.Payload);
        for block in bs.Blocks do
          FReceiver.ReceiveSnapshotBlock(block, bsFetch);
        if Length(bs.Blocks) > 0 then
          Done(Msg.Id, Msg.Sender, Msg, nil);
      end;
    CodeAccountBlocks:
      begin
        ab := TAccountBlocks.Create;
        ab.Deserialize(Msg.Payload);
        for ablock in ab.Blocks do
          FReceiver.ReceiveAccountBlock(ablock, bsFetch);
        if Length(ab.Blocks) > 0 then
          Done(Msg.Id, Msg.Sender, Msg, nil);
      end;
    CodeException:
      Done(Msg.Id, Msg.Sender, Msg, Exception.Create('No resource'));
  end;
end;

procedure TFetcher.Done(Id: TMsgId; Peer: TPeer; Msg: TMsg; Err: Exception);
var
  r: TFetchRecord;
  now: Int64;
  result: PPeerFetchResult;
  rest: Integer;
begin
  FCritSect.Enter;
  try
    if FRecordsById.TryGetValue(Id, r) then
    begin
      now := Round(Now * 86400);
      if Assigned(Peer) and r.Targets.TryGetValue(Peer.Id, result) then
      begin
        if Err <> nil then
        begin
          result.Status := rsError;
          result.T := now;
        end
        else
        begin
          result.Status := rsDone;
          result.T := now;
        end;
      end;
      if r.St <> rsPending then Exit;
      if Err = nil then
      begin
        r.St := rsDone;
        r.T := now;
        if Assigned(r.Callback) then
          TThread.CreateAnonymousThread(procedure begin r.Callback(Msg, nil); end).Start;
      end
      else
      begin
        rest := 0;
        for result in r.Targets.Values do
          if result.Status <> rsError then
            Inc(rest);
        if rest = 0 then
        begin
          r.St := rsError;
          r.T := now;
          if Assigned(r.Callback) then
            TThread.CreateAnonymousThread(procedure begin r.Callback(Msg, Err); end).Start;
        end;
      end;
    end;
  finally
    FCritSect.Leave;
  end;
end;

procedure TFetcher.FetchSnapshotBlocks(const Start: THash; Count: UInt64);
begin
  // Placeholder implementation
end;

procedure TFetcher.FetchSnapshotBlocksWithHeight(const Hash: THash; Height, Count: UInt64);
begin
  // Placeholder implementation
end;

procedure TFetcher.FetchAccountBlocks(const Start: THash; Count: UInt64; Address: PAddress);
begin
  // Placeholder implementation
end;

procedure TFetcher.FetchAccountBlocksWithHeight(const Start: THash; Count: UInt64; Address: PAddress; SHeight: UInt64);
begin
  // Placeholder implementation
end;

end.