{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/net/net.go
}
unit V.Net.Net;

interface

uses
  System.SysUtils, System.Classes, System.Net.Socket, System.Generics.Collections,
  V.Common.Config, V.Common.Types, V.Crypto.Ed25519, V.Interfaces.Core,
  V.Net.Database, V.Net.Discovery, V.Net.VNode, V.Net.Interface,
  V.Net.Syncer, V.Net.Fetcher, V.Net.Broadcaster, V.Net.MsgHandler,
  V.Net.Handshaker, V.Net.Peer, V.Ledger.Consensus;

type
  TNet = class(TInterfacedObject, INet, IConnector)
  private
    FConfig: TNetConfig; // Assuming TNetConfig is defined in V.Common.Config
    FPeerKey: TPrivateKey;
    FNode: PNode;
    FFinder: TFinder;
    FDiscover: TDiscovery;
    FDB: TDB;
    FListener: TSocket;
    FHandshaker: THandshaker;
    FReceiveSlots: TSemaphore;
    FConfirmedHashHeightList: TArray<PHashHeight>;
    FSyncServer: TSyncServer;
    FPeers: TPeerSet;
    FChain: IChain;
    FSyncer: ISyncer;
    FFetcher: IFetcher;
    FBroadcaster: IBroadcaster;
    FBlockSubscriber: IBlockSubscriber;
    FHandlers: TMsgHandlers;
    FQuery: TQueryHandler;
    FHeartBeater: TObject; // Placeholder for THeartBeater
    FBlackList: IBlackList; // Assuming IBlackList is defined
    FRunning: Integer;
    FWaitGroup: TCountdownEvent;
    FLog: TObject; // Placeholder for TLogger
    procedure ListenLoop;
    procedure OnConnection(Conn: TSocket; const Id: TNodeID; Inbound: Boolean);
    function Authorize(const C: ICodec; Flag: TPeerFlags; const Msg: THandshakeMsg): Boolean;
    procedure OnPeerAdded(Peer: TPeer);
    procedure OnPeerRemoved(Peer: TPeer);
  public
    constructor Create(ACfg: TNetConfig; AChain: IChain; AVerifier: IVerifier; AConsensus: IConsensus; AIrreader: IIrreversibleReader);
    destructor Destroy; override;
    // INet methods
    procedure Start;
    procedure Stop;
    function Info: TNodeInfo;
    function Nodes: TNodeArray;
    function PeerCount: Integer;
    function PeerKey: TPrivateKey;
    // IConnector
    procedure ConnectNode(Node: PNode);
    // Other INet interfaces are implemented by delegation
    function Status: TSyncStatus;
    function Detail: TSyncDetail;
    function Peek: TChunk;
    procedure Pop(const EndHash: THash);
    procedure FetchSnapshotBlocks(const Start: THash; Count: UInt64);
    procedure FetchSnapshotBlocksWithHeight(const Hash: THash; Height, Count: UInt64);
    procedure FetchAccountBlocks(const Start: THash; Count: UInt64; Address: PAddress);
    procedure FetchAccountBlocksWithHeight(const Start: THash; Count: UInt64; Address: PAddress; SHeight: UInt64);
    procedure BroadcastSnapshotBlock(Block: PSnapshotBlock);
    procedure BroadcastSnapshotBlocks(const Blocks: TSnapshotChunkArray);
    procedure BroadcastAccountBlock(Block: PAccountBlock);
    procedure BroadcastAccountBlocks(const Blocks: TAccountBlockArray);
    function SubscribeAccountBlock(Fn: TAccountBlockCallback): Integer;
    procedure UnsubscribeAccountBlock(SubId: Integer);
    function SubscribeSnapshotBlock(Fn: TSnapshotBlockCallback): Integer;
    procedure UnsubscribeSnapshotBlock(SubId: Integer);
    function SubscribeSyncStatus(Fn: TSyncStateCallback): Integer;
    procedure UnsubscribeSyncStatus(SubId: Integer);
    function SyncState: TSyncState;
  end;

implementation

uses System.Threading, V.Net.PeerError;

{ TNet }

constructor TNet.Create(ACfg: TNetConfig; AChain: IChain; AVerifier: IVerifier; AConsensus: IConsensus; AIrreader: IIrreversibleReader);
begin
  // A very simplified constructor. A full implementation would be much more complex.
  inherited Create;
  FConfig := ACfg;
  // FPeerKey := ACfg.Init; // Assuming Init returns a key
  FPeers := TPeerSet.Create;
  FBlockSubscriber := TBlockFeed.Create(nil);
  // ... Initialize all other components (fetcher, syncer, etc.)
end;

destructor TNet.Destroy;
begin
  Stop;
  // Free all components
  inherited Destroy;
end;

procedure TNet.Start;
begin
  if TInterlocked.CompareExchange(FRunning, 1, 0) = 0 then
  begin
    // Start all components (listener, discover, finder, syncer, etc.)
    TThread.CreateAnonymousThread(ListenLoop).Start;
  end;
end;

procedure TNet.Stop;
begin
  if TInterlocked.CompareExchange(FRunning, 0, 1) = 1 then
  begin
    // Stop all components
  end;
end;

procedure TNet.ListenLoop;
var conn: TSocket;
begin
  while FRunning = 1 do
  begin
    conn := FListener.Accept;
    if Assigned(conn) then
    begin
      FReceiveSlots.Acquire;
      TThread.CreateAnonymousThread(procedure begin OnConnection(conn, TNodeID.Default, True); end).Start;
    end;
  end;
end;

procedure TNet.OnConnection(Conn: TSocket; const Id: TNodeID; Inbound: Boolean);
var
  c: ICodec;
  their: THandshakeMsg;
  superior: Boolean;
  flag: TPeerFlags;
  peer: TPeer;
begin
  if Inbound then
    flag := [pfInbound]
  else
    flag := [pfOutbound];

  // Simplified handshake logic
  if Inbound then
    FHandshaker.ReceiveHandshake(Conn, c, their, superior)
  else
    FHandshaker.InitiateHandshake(Conn, Id, c, their, superior);

  // peer := TPeer.Create(c, their, ...);
  OnPeerAdded(peer);
  OnPeerRemoved(peer);
end;

function TNet.Authorize(const C: ICodec; Flag: TPeerFlags; const Msg: THandshakeMsg): Boolean;
begin
  // Placeholder for authorization logic
  Result := True;
end;

procedure TNet.OnPeerAdded(Peer: TPeer);
begin
  FPeers.Add(Peer);
  // ... peer.Run ...
end;

procedure TNet.OnPeerRemoved(Peer: TPeer);
begin
  FPeers.Remove(Peer.Id);
end;

procedure TNet.ConnectNode(Node: PNode);
var conn: TSocket;
begin
  if FPeers.Has(Node.ID) then raise EPeerError.Create(peAlreadyConnected);
  // ... Dialing logic ...
  conn := TSocket.Create(TSocketType.stStream);
  // conn.Connect(Node.Address);
  TThread.CreateAnonymousThread(procedure begin OnConnection(conn, Node.ID, False); end).Start;
end;

// ... Implementations for all INet interface methods by delegation ...
function TNet.Info: TNodeInfo; begin FillChar(Result, SizeOf(TNodeInfo), 0); end;
function TNet.Nodes: TNodeArray; begin Result := nil; end;
function TNet.PeerCount: Integer; begin Result := FPeers.Count; end;
function TNet.PeerKey: TPrivateKey; begin Result := FPeerKey; end;
function TNet.Status: TSyncStatus; begin Result := FSyncer.Status; end;
function TNet.Detail: TSyncDetail; begin Result := FSyncer.Detail; end;
function TNet.Peek: TChunk; begin Result := FSyncer.Peek; end;
procedure TNet.Pop(const EndHash: THash); begin FSyncer.Pop(EndHash); end;
procedure TNet.FetchSnapshotBlocks(const Start: THash; Count: UInt64); begin FFetcher.FetchSnapshotBlocks(Start, Count); end;
procedure TNet.FetchSnapshotBlocksWithHeight(const Hash: THash; Height, Count: UInt64); begin FFetcher.FetchSnapshotBlocksWithHeight(Hash, Height, Count); end;
procedure TNet.FetchAccountBlocks(const Start: THash; Count: UInt64; Address: PAddress); begin FFetcher.FetchAccountBlocks(Start, Count, Address); end;
procedure TNet.FetchAccountBlocksWithHeight(const Start: THash; Count: UInt64; Address: PAddress; SHeight: UInt64); begin FFetcher.FetchAccountBlocksWithHeight(Start, Count, Address, SHeight); end;
procedure TNet.BroadcastSnapshotBlock(Block: PSnapshotBlock); begin FBroadcaster.BroadcastSnapshotBlock(Block); end;
procedure TNet.BroadcastSnapshotBlocks(const Blocks: TSnapshotChunkArray); begin FBroadcaster.BroadcastSnapshotBlocks(Blocks); end;
procedure TNet.BroadcastAccountBlock(Block: PAccountBlock); begin FBroadcaster.BroadcastAccountBlock(Block); end;
procedure TNet.BroadcastAccountBlocks(const Blocks: TAccountBlockArray); begin FBroadcaster.BroadcastAccountBlocks(Blocks); end;
function TNet.SubscribeAccountBlock(Fn: TAccountBlockCallback): Integer; begin Result := FBlockSubscriber.SubscribeAccountBlock(Fn); end;
procedure TNet.UnsubscribeAccountBlock(SubId: Integer); begin FBlockSubscriber.UnsubscribeAccountBlock(SubId); end;
function TNet.SubscribeSnapshotBlock(Fn: TSnapshotBlockCallback): Integer; begin Result := FBlockSubscriber.SubscribeSnapshotBlock(Fn); end;
procedure TNet.UnsubscribeSnapshotBlock(SubId: Integer); begin FBlockSubscriber.UnsubscribeSnapshotBlock(SubId); end;
function TNet.SubscribeSyncStatus(Fn: TSyncStateCallback): Integer; begin Result := FSyncer.SubscribeSyncStatus(Fn); end;
procedure TNet.UnsubscribeSyncStatus(SubId: Integer); begin FSyncer.UnsubscribeSyncStatus(SubId); end;
function TNet.SyncState: TSyncState; begin Result := FSyncer.SyncState; end;

end.