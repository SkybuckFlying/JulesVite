{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/net/sync_server.go
}
unit V.Net.SyncServer;

interface

uses
  System.SysUtils, System.Classes, System.Net.Socket, System.Generics.Collections,
  V.Net.SyncConn, V.Interfaces, V.Net.Peer;

type
  TFileServerStatus = record
    Connections: TArray<string>; // Simplified from SyncConnectionStatus
  end;

  TSyncServer = class
  private
    FAddr: string;
    FListener: TSocket;
    FCritSect: TCriticalSection;
    FConnMap: TDictionary<TNodeID, TSyncConn>;
    FChain: ILedgerReaderProvider;
    FFactory: ISyncConnReceiver;
    FRunning: Integer;
    FWaitGroup: TCountdownEvent;
    FLog: TObject; // Placeholder for V.Log15.TLogger
    procedure ListenLoop;
    procedure HandleConn(Conn: TSocket);
    procedure AddConn(Conn: TSyncConn);
    procedure DeleteConn(Conn: TSyncConn);
  public
    constructor Create(AAddr: string; AChain: ILedgerReaderProvider; AFactory: ISyncConnReceiver);
    destructor Destroy; override;
    function Start: Boolean;
    procedure Stop;
    function Status: TFileServerStatus;
  end;

implementation

uses System.Threading, V.Net.Message, V.Net.PeerError;

{ TSyncServer }

constructor TSyncServer.Create(AAddr: string; AChain: ILedgerReaderProvider; AFactory: ISyncConnReceiver);
begin
  inherited Create;
  FAddr := AAddr;
  FChain := AChain;
  FFactory := AFactory;
  FCritSect := TCriticalSection.Create;
  FConnMap := TDictionary<TNodeID, TSyncConn>.Create;
  // FLog := V.Log15.GLog.New('module', 'server');
end;

destructor TSyncServer.Destroy;
begin
  Stop;
  FCritSect.Free;
  FConnMap.Free;
  inherited Destroy;
end;

function TSyncServer.Start: Boolean;
begin
  if TInterlocked.CompareExchange(FRunning, 1, 0) = 0 then
  begin
    try
      FListener := TSocket.Create(TSocketType.stStream);
      // Binding and listening logic would go here
      FListener.Listen;
      FWaitGroup := TCountdownEvent.Create;
      TThread.CreateAnonymousThread(ListenLoop).Start;
      Result := True;
    except
      Result := False;
    end;
  end
  else
    raise Exception.Create('Sync server is already running');
end;

procedure TSyncServer.Stop;
var
  conn: TSyncConn;
begin
  if TInterlocked.CompareExchange(FRunning, 0, 1) = 1 then
  begin
    if Assigned(FListener) then
      FListener.Close;
    for conn in FConnMap.Values do
      conn.Close;
    FConnMap.Clear;
    if Assigned(FWaitGroup) then
    begin
      FWaitGroup.Wait;
      FWaitGroup.Free;
    end;
  end;
end;

procedure TSyncServer.ListenLoop;
var
  conn: TSocket;
begin
  FWaitGroup.Add;
  try
    while FRunning = 1 do
    begin
      try
        conn := FListener.Accept;
        if Assigned(conn) then
        begin
          FWaitGroup.Add;
          TThread.CreateAnonymousThread(procedure begin HandleConn(conn); end).Start;
        end;
      except
        // Handle exceptions, temporary errors etc.
        TThread.Sleep(100);
      end;
    end;
  finally
    FWaitGroup.Signal;
  end;
end;

procedure TSyncServer.HandleConn(Conn: TSocket);
var
  syncConn: TSyncConn;
  msg: TMsg;
  request: TSyncRequest; // Assuming TSyncRequest is defined
  reader: ILedgerReader;
  segment: TSegment;
  ready: TSyncResponse; // Assuming TSyncResponse is defined
  data: TBytes;
begin
  FWaitGroup.Add;
  try
    syncConn := FFactory.Receive(Conn);
    if syncConn = nil then Exit;
    AddConn(syncConn);
    try
      while True do
      begin
        msg := syncConn.FCodec.ReadMsg;
        if msg.Code = CodeDisconnect then Exit;
        if msg.Code <> CodeSyncRequest then Continue;
        // request := TSyncRequest.Create;
        // request.Deserialize(msg.Payload);
        // reader := FChain.GetLedgerReaderByHeight(request.From, request.To);
        // ... rest of the logic
      end;
    finally
      DeleteConn(syncConn);
    end;
  finally
    FWaitGroup.Signal;
  end;
end;

procedure TSyncServer.AddConn(Conn: TSyncConn);
begin
  if TInterlocked.Read(FRunning) = 1 then
  begin
    FCritSect.Enter;
    try
      FConnMap.Add(Conn.FPeer.Id, Conn);
    finally
      FCritSect.Leave;
    end;
  end;
end;

procedure TSyncServer.DeleteConn(Conn: TSyncConn);
begin
  Conn.Close;
  if TInterlocked.Read(FRunning) = 1 then
  begin
    FCritSect.Enter;
    try
      FConnMap.Remove(Conn.FPeer.Id);
    finally
      FCritSect.Leave;
    end;
  end;
end;

function TSyncServer.Status: TFileServerStatus;
begin
  // Placeholder
end;

end.