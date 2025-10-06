{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/net/sync_downloader.go
}
unit V.Net.SyncDownloader;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  V.Interfaces, V.Net.Peer, V.Net.SyncConn;

type
  TReqState = (rsWaiting, rsPending, rsDone, rsError, rsCancel);

  TSyncTask = class
  public
    Segment: TSegment;
    St: TReqState;
    DoneAt: TDateTime;
    Source: TNodeID;
    procedure WaitState;
    procedure Cancel;
    procedure Pending;
    procedure Done;
    procedure Error;
    function Equal(T2: TSyncTask): Boolean;
    function Status: string;
  end;

  TDownloaderStatus = record
    Tasks: TArray<string>;
    Connections: TArray<string>; // Simplified from SyncConnectionStatus
  end;

  TTaskListener = procedure(T: TSyncTask; Err: Exception);

  ISyncDownloader = interface
    ['{A1B2C3D4-E5F6-4A8B-9C8D-7E6F5A4B3C2D}']
    procedure Start;
    procedure Stop;
    function Status: TDownloaderStatus;
    function Download(T: TSyncTask; Must: Boolean): Boolean;
    procedure CancelAllTasks;
    procedure CancelTask(T: TSyncTask);
    procedure AddListener(Listener: TTaskListener);
    procedure AddBlackList(const Id: TNodeID);
  end;

  TExecutor = class(TInterfacedObject, ISyncDownloader)
  private
    FCritSect: TCriticalSection;
    FCond: TConditionVariable;
    FTasks: TList<TSyncTask>;
    FMax, FBatch: Integer;
    FPool: TDownloadConnPool;
    FFactory: ISyncConnInitiator;
    FDialing: TDictionary<string, Boolean>;
    FListeners: TList<TTaskListener>;
    FRunning: Boolean;
    FLoopThread: TThread;
    procedure Loop;
    procedure RunTask(T: TSyncTask);
    procedure DoTask(T: TSyncTask);
    procedure NotifyListeners(T: TSyncTask; Err: Exception);
  public
    constructor Create(AMax, ABatch: Integer; APeers: TPeerSet; AFactory: ISyncConnInitiator);
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    function Status: TDownloaderStatus;
    function Download(T: TSyncTask; Must: Boolean): Boolean;
    procedure CancelAllTasks;
    procedure CancelTask(T: TSyncTask);
    procedure AddListener(Listener: TTaskListener);
    procedure AddBlackList(const Id: TNodeID);
  end;

implementation

uses System.Threading;

{ TSyncTask }
procedure TSyncTask.WaitState; begin St := rsWaiting; end;
procedure TSyncTask.Cancel; begin St := rsCancel; end;
procedure TSyncTask.Pending; begin St := rsPending; end;
procedure TSyncTask.Done; begin St := rsDone; DoneAt := Now; end;
procedure TSyncTask.Error; begin if St = rsPending then St := rsError; end;
function TSyncTask.Equal(T2: TSyncTask): Boolean;
begin
  // Simplified equality check
  Result := (Self.Segment.From = T2.Segment.From) and (Self.Segment.To_ = T2.Segment.To_);
end;
function TSyncTask.Status: string;
begin
  Result := Format('%d-%d %s', [Segment.From, Segment.To_, '...']); // Simplified
end;


{ TExecutor }
constructor TExecutor.Create(AMax, ABatch: Integer; APeers: TPeerSet; AFactory: ISyncConnInitiator);
begin
  inherited Create;
  FMax := AMax;
  FBatch := ABatch;
  FTasks := TList<TSyncTask>.Create;
  FPool := TDownloadConnPool.Create(APeers);
  FFactory := AFactory;
  FDialing := TDictionary<string, Boolean>.Create;
  FListeners := TList<TTaskListener>.Create;
  FCritSect := TCriticalSection.Create;
  FCond := TConditionVariable.Create;
end;
destructor TExecutor.Destroy;
begin
  Stop;
  FTasks.Free;
  FPool.Free;
  FDialing.Free;
  FListeners.Free;
  FCritSect.Free;
  FCond.Free;
  inherited Destroy;
end;

procedure TExecutor.Start;
begin
  FCritSect.Enter;
  try
    if FRunning then Exit;
    FRunning := True;
    FTasks.Clear;
    FLoopThread := TThread.CreateAnonymousThread(Loop);
    FLoopThread.Start;
  finally
    FCritSect.Leave;
  end;
end;

procedure TExecutor.Stop;
begin
  FCritSect.Enter;
  try
    if not FRunning then Exit;
    FRunning := False;
  finally
    FCritSect.Leave;
  end;
  FCond.Broadcast;
  if Assigned(FLoopThread) then
    FLoopThread.WaitFor;
end;

procedure TExecutor.Loop;
var
  total, batch, peerCount, i: Integer;
  task: TSyncTask;
begin
  while FRunning do
  begin
    FCritSect.Enter;
    while (FTasks.Count = 0) and FRunning do
      FCond.Wait(FCritSect);
    if not FRunning then
    begin
      FCritSect.Leave;
      Break;
    end;
    total := FTasks.Count;
    // Simplified run logic
    for i := 0 to Min(FBatch - 1, total - 1) do
    begin
      task := FTasks[i];
      if task.St = rsWaiting then
        RunTask(task);
    end;
    FCritSect.Leave;
    TThread.Sleep(100);
  end;
end;

procedure TExecutor.RunTask(T: TSyncTask);
begin
  T.Pending;
  TTask.Run(procedure begin DoTask(T); end);
end;

procedure TExecutor.DoTask(T: TSyncTask);
var
  p: TPeer;
  c: TSyncConn;
  err: Exception;
begin
  err := nil;
  try
    if FPool.ChooseSource(T, p, c) then
    begin
      if c <> nil then
      begin
        if c.Download(T) then T.Done;
      end
      else if p <> nil then
      begin
        // Simplified: create connection and download
      end;
    end;
  except
    on E: Exception do
      err := E;
  end;
  if T.St = rsPending then T.Error;
  if T.St = rsDone then NotifyListeners(T, err);
end;

procedure TExecutor.NotifyListeners(T: TSyncTask; Err: Exception);
var listener: TTaskListener;
begin
  for listener in FListeners do
    listener(T, Err);
end;

function TExecutor.Status: TDownloaderStatus; begin end;
function TExecutor.Download(T: TSyncTask; Must: Boolean): Boolean;
begin
  FCritSect.Enter;
  try
    if not Must then
      while (FTasks.Count = FMax) and FRunning do
        FCond.Wait(FCritSect);
    if not FRunning then Exit(False);
    FTasks.Add(T);
    FTasks.Sort;
  finally
    FCritSect.Leave;
  end;
  FCond.Signal;
  Result := True;
end;
procedure TExecutor.CancelAllTasks; begin FCritSect.Enter; try FTasks.Clear; finally FCritSect.Leave; end; FCond.Broadcast; end;
procedure TExecutor.CancelTask(T: TSyncTask); begin FCritSect.Enter; try FTasks.Remove(T); finally FCritSect.Leave; end; FCond.Signal; end;
procedure TExecutor.AddListener(Listener: TTaskListener); begin FListeners.Add(Listener); end;
procedure TExecutor.AddBlackList(const Id: TNodeID); begin FPool.BlockPeer(Id, TTimeSpan.FromSeconds(60)); end;

end.