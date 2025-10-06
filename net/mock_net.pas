{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/net/mock_net.go
}
unit V.Net.MockNet;

interface

uses
  System.SysUtils,
  V.Common.Types, V.Crypto.Ed25519, V.Interfaces.Core, V.Net.VNode,
  V.Net.Interface;

type
  TMockNet = class(TInterfacedObject, INet)
  private
    FChain: IChain;
  public
    constructor Create(AChain: IChain);
    // ISyncer
    function Status: TSyncStatus;
    function Detail: TSyncDetail;
    function Peek: TChunk;
    procedure Pop(const EndHash: THash);
    // IFetcher
    procedure FetchSnapshotBlocks(const Start: THash; Count: UInt64);
    procedure FetchSnapshotBlocksWithHeight(const Hash: THash; Height, Count: UInt64);
    procedure FetchAccountBlocks(const Start: THash; Count: UInt64; Address: PAddress);
    procedure FetchAccountBlocksWithHeight(const Start: THash; Count: UInt64; Address: PAddress; SHeight: UInt64);
    // IBroadcaster
    procedure BroadcastSnapshotBlock(Block: PSnapshotBlock);
    procedure BroadcastSnapshotBlocks(const Blocks: TSnapshotChunkArray);
    procedure BroadcastAccountBlock(Block: PAccountBlock);
    procedure BroadcastAccountBlocks(const Blocks: TAccountBlockArray);
    // IBlockSubscriber
    function SubscribeAccountBlock(Fn: TAccountBlockCallback): Integer;
    procedure UnsubscribeAccountBlock(SubId: Integer);
    function SubscribeSnapshotBlock(Fn: TSnapshotBlockCallback): Integer;
    procedure UnsubscribeSnapshotBlock(SubId: Integer);
    // ISyncStateSubscriber
    function SubscribeSyncStatus(Fn: TSyncStateCallback): Integer;
    procedure UnsubscribeSyncStatus(SubId: Integer);
    function SyncState: TSyncState;
    // INet
    procedure Start;
    procedure Stop;
    function Info: TNodeInfo;
    function Nodes: TNodeArray;
    function PeerCount: Integer;
    function PeerKey: TPrivateKey;
  end;

function Mock(Chain: IChain): INet;

implementation

{ TMockNet }

constructor TMockNet.Create(AChain: IChain);
begin
  inherited Create;
  FChain := AChain;
end;

function TMockNet.PeerKey: TPrivateKey;
begin
  FillChar(Result, SizeOf(TPrivateKey), 0);
end;

function TMockNet.SubscribeSyncStatus(Fn: TSyncStateCallback): Integer;
begin
  Result := 0;
end;

procedure TMockNet.UnsubscribeSyncStatus(SubId: Integer);
begin
end;

function TMockNet.SyncState: TSyncState;
begin
  Result := ssSynced;
end;

function TMockNet.Peek: TChunk;
begin
  // Result is implicitly nil for record types
end;

procedure TMockNet.Pop(const EndHash: THash);
begin
end;

function TMockNet.Status: TSyncStatus;
begin
  // Result is implicitly zeroed
end;

function TMockNet.Detail: TSyncDetail;
begin
  // Result is implicitly zeroed
end;

procedure TMockNet.FetchSnapshotBlocks(const Start: THash; Count: UInt64);
begin
end;

procedure TMockNet.FetchSnapshotBlocksWithHeight(const Hash: THash; Height, Count: UInt64);
begin
end;

procedure TMockNet.FetchAccountBlocks(const Start: THash; Count: UInt64; Address: PAddress);
begin
end;

procedure TMockNet.FetchAccountBlocksWithHeight(const Start: THash; Count: UInt64; Address: PAddress; SHeight: UInt64);
begin
end;

procedure TMockNet.BroadcastSnapshotBlock(Block: PSnapshotBlock);
begin
end;

procedure TMockNet.BroadcastSnapshotBlocks(const Blocks: TSnapshotChunkArray);
begin
end;

procedure TMockNet.BroadcastAccountBlock(Block: PAccountBlock);
begin
end;

procedure TMockNet.BroadcastAccountBlocks(const Blocks: TAccountBlockArray);
begin
end;

function TMockNet.SubscribeAccountBlock(Fn: TAccountBlockCallback): Integer;
begin
  Result := 0;
end;

procedure TMockNet.UnsubscribeAccountBlock(SubId: Integer);
begin
end;

function TMockNet.SubscribeSnapshotBlock(Fn: TSnapshotBlockCallback): Integer;
begin
  Result := 0;
end;

procedure TMockNet.UnsubscribeSnapshotBlock(SubId: Integer);
begin
end;

procedure TMockNet.Start;
begin
end;

procedure TMockNet.Stop;
begin
end;

function TMockNet.Info: TNodeInfo;
begin
  // Result is implicitly zeroed
end;

function TMockNet.Nodes: TNodeArray;
begin
  Result := nil;
end;

function TMockNet.PeerCount: Integer;
begin
  Result := 0;
end;

function Mock(Chain: IChain): INet;
begin
  Result := TMockNet.Create(Chain);
end;

end.