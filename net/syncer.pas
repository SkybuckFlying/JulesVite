{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/net/syncer.go
}
unit V.Net.Syncer;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  V.Common.Types, V.Interfaces, V.Interfaces.Core, V.Net.Interface,
  V.Net.Peer, V.Net.SyncState, V.Net.Skeleton, V.Net.SyncCacheReader,
  V.Net.SyncDownloader, V.Log15;

type
  TSyncer = class(TInterfacedObject, ISyncer, IMsgHandler, ISyncStateHost)
  private
    FSbp: Boolean;
    FSyncing: Integer;
    FFrom, FTo: UInt64;
    FState: ISyncState;
    FTimeout: TTimeSpan;
    FPeers: TPeerSet;
    FEventChan: TChannel<TPeerEvent>;
    FTaskCanceled: Integer;
    FSkeleton: TSkeleton;
    FSyncWaitGroup: TCountdownEvent;
    FChain: ISyncChain;
    FDownloader: ISyncDownloader;
    FReader: ISyncCacheReader;
    FIrreader: IIrreversibleReader;
    FSubs: TDictionary<Integer, TSyncStateCallback>;
    FCritSect: TCriticalSection;
    FRunning: Integer;
    FTerm: TEvent;
    FLog: TLogger;
    FCheckLoopThread: TThread;
    procedure CheckLoop;
    procedure StartSyncProcess;
    function GetHeight: UInt64;
    function GetInitStart: TArray<PHashHeight>;
    function GetEnd(const Start: TArray<PHashHeight>): UInt64;
    function GetHashHeightList(const Start: TArray<PHashHeight>; EndHeight: UInt64): TArray<THashHeightPoint>;
    function VerifyHashHeightList(const Start: TArray<PHashHeight>; const Points: TArray<THashHeightPoint>): PHashHeight;
    procedure Sync;
    procedure DownloadLoop(StartPoint: PHashHeight; EndHeight: UInt64; const Points: TArray<THashHeightPoint>);
    procedure StopSync;
  public
    constructor Create(AChain: ISyncChain; APeers: TPeerSet; AReader: ISyncCacheReader; ADownloader: ISyncDownloader; AIrreader: IIrreversibleReader; ATimeout: TTimeSpan; ABlackBlocks: TDictionary<THash, Boolean>);
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    // ISyncer
    function Status: TSyncStatus;
    function Detail: TSyncDetail;
    function Peek: TChunk;
    procedure Pop(const EndHash: THash);
    // IMsgHandler
    function Name: string;
    function Codes: TArray<TCode>;
    procedure Handle(const Msg: TMsg);
    // ISyncStateHost
    procedure SetState(AState: ISyncState);
    // ISyncStateSubscriber
    function SubscribeSyncStatus(Fn: TSyncStateCallback): Integer;
    procedure UnsubscribeSyncStatus(SubId: Integer);
    function SyncState: TSyncState;
  end;

implementation

uses System.Threading;

{ TSyncer }
constructor TSyncer.Create(AChain: ISyncChain; APeers: TPeerSet; AReader: ISyncCacheReader; ADownloader: ISyncDownloader; AIrreader: IIrreversibleReader; ATimeout: TTimeSpan; ABlackBlocks: TDictionary<THash, Boolean>);
begin
  inherited Create;
  FChain := AChain;
  FPeers := APeers;
  FReader := AReader;
  FDownloader := ADownloader;
  FIrreader := AIrreader;
  FTimeout := ATimeout;
  FSubs := TDictionary<Integer, TSyncStateCallback>.Create;
  FCritSect := TCriticalSection.Create;
  FLog := V.Log15.GLog;
  FSkeleton := TSkeleton.Create(FPeers, 0, ABlackBlocks);
  FState := TSyncStateInit.Create(Self);
end;

destructor TSyncer.Destroy;
begin
  Stop;
  FSubs.Free;
  FCritSect.Free;
  FSkeleton.Free;
  inherited Destroy;
end;

procedure TSyncer.Start;
begin
  if TInterlocked.CompareExchange(FRunning, 1, 0) = 0 then
  begin
    FCheckLoopThread := TThread.CreateAnonymousThread(CheckLoop);
    FCheckLoopThread.Start;
  end;
end;

procedure TSyncer.Stop;
begin
  if TInterlocked.CompareExchange(FRunning, 0, 1) = 1 then
  begin
    if Assigned(FTerm) then FTerm.SetEvent;
    StopSync;
    if Assigned(FCheckLoopThread) then FCheckLoopThread.WaitFor;
  end;
end;

procedure TSyncer.SetState(AState: ISyncState);
var
  subs: TArray<TSyncStateCallback>;
  sub: TSyncStateCallback;
begin
  FState := AState;
  FCritSect.Enter;
  try
    subs := FSubs.Values.ToArray;
  finally
    FCritSect.Leave;
  end;
  for sub in subs do
    sub(AState.GetState);
end;

procedure TSyncer.CheckLoop;
var
  currentHeight: UInt64;
  syncPeer: TPeer;
begin
  while FRunning do
  begin
    TThread.Sleep(3000);
    if not FRunning then Exit;
    currentHeight := FChain.GetLatestSnapshotBlock.Height;
    syncPeer := FPeers.BestPeer; // Simplified
    if syncPeer = nil then Continue;
    if TInterlocked.Read(FSyncing) = 1 then Continue;
    if (syncPeer.Height >= currentHeight + 100) or (FState.GetState <> ssDone) then
      TThread.CreateAnonymousThread(StartSyncProcess).Start;
  end;
end;

procedure TSyncer.StartSyncProcess;
var
  syncPeer: TPeer;
  currentHeight, syncPeerHeight: UInt64;
begin
  if TInterlocked.CompareExchange(FSyncing, 1, 0) <> 0 then Exit;
  try
    FTerm := TEvent.Create(nil, True, False, '');
    try
      syncPeer := FPeers.BestPeer; // Simplified
      if syncPeer = nil then
      begin
        FState.Error(seNoPeers);
        Exit;
      end;
      syncPeerHeight := syncPeer.Height;
      currentHeight := GetHeight;
      if not (syncPeerHeight >= currentHeight + 100) then
      begin
        FState.Done;
        Exit;
      end;
      FFrom := currentHeight + 1;
      FTo := syncPeerHeight;
      Sync;
      FState.Sync;
      // ... more logic from the original start method ...
    finally
      FTerm.Free;
      FTerm := nil;
    end;
  finally
    TInterlocked.Exchange(FSyncing, 0);
  end;
end;

procedure TSyncer.Sync;
var
  start: TArray<PHashHeight>;
  &end: UInt64;
  points: TArray<THashHeightPoint>;
  startPoint: PHashHeight;
begin
  start := GetInitStart;
  &end := GetEnd(start);
  points := GetHashHeightList(start, &end);
  startPoint := VerifyHashHeightList(start, points);
  FReader.Reset;
  FFrom := startPoint.Height + 1;
  TThread.CreateAnonymousThread(procedure begin DownloadLoop(startPoint, &end, points); end).Start;
end;

procedure TSyncer.DownloadLoop(StartPoint: PHashHeight; EndHeight: UInt64; const Points: TArray<THashHeightPoint>);
begin
  // Placeholder for the complex download loop logic
end;

procedure TSyncer.StopSync;
begin
  TInterlocked.Exchange(FTaskCanceled, 1);
  FDownloader.CancelAllTasks;
  FReader.Reset;
  // FSyncWaitGroup.Wait; // Simplified
end;

function TSyncer.GetHeight: UInt64; begin Result := FChain.GetLatestSnapshotBlock.Height; end;
function TSyncer.GetInitStart: TArray<PHashHeight>; begin Result := nil; end; // Placeholder
function TSyncer.GetEnd(const Start: TArray<PHashHeight>): UInt64; begin Result := 0; end; // Placeholder
function TSyncer.GetHashHeightList(const Start: TArray<PHashHeight>; EndHeight: UInt64): TArray<THashHeightPoint>; begin Result := FSkeleton.Construct(Start, EndHeight); end;
function TSyncer.VerifyHashHeightList(const Start: TArray<PHashHeight>; const Points: TArray<THashHeightPoint>): PHashHeight; begin Result := nil; end; // Placeholder

function TSyncer.Status: TSyncStatus; begin FillChar(Result, SizeOf(TSyncStatus), 0); end;
function TSyncer.Detail: TSyncDetail; begin FillChar(Result, SizeOf(TSyncDetail), 0); end;
function TSyncer.Peek: TChunk; begin Result := FReader.Peek; end;
procedure TSyncer.Pop(const EndHash: THash); begin FReader.Pop(EndHash); end;
function TSyncer.Name: string; begin Result := 'syncer'; end;
function TSyncer.Codes: TArray<TCode>; begin SetLength(Result, 1); Result[0] := CodeHashList; end;
procedure TSyncer.Handle(const Msg: TMsg); begin if Msg.Code = CodeHashList then FSkeleton.ReceiveHashList(Msg, Msg.Sender); end;
function TSyncer.SubscribeSyncStatus(Fn: TSyncStateCallback): Integer; begin FCritSect.Enter; try Result := FSubs.Count; FSubs.Add(Result, Fn); finally FCritSect.Leave; end; end;
procedure TSyncer.UnsubscribeSyncStatus(SubId: Integer); begin FCritSect.Enter; try FSubs.Remove(SubId); finally FCritSect.Leave; end; end;
function TSyncer.SyncState: TSyncState; begin Result := FState.GetState; end;

end.