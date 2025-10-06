{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/net/sync_conn.go
}
unit V.Net.SyncConn;

interface

uses
  System.SysUtils, System.Classes, System.Net.Socket, System.Generics.Collections,
  V.Common.Types, V.Crypto.Ed25519, V.Net.VNode, V.Interfaces, V.Net.Message,
  V.Net.Peer;

type
  TSyncConn = class; // Forward declaration
  TSyncTask = class; // Forward declaration

  ISyncConnInitiator = interface
    ['{A1B2C3D4-E5F6-4A8B-9C8D-7E6F5A4B3C2D}']
    function Initiate(Conn: TSocket; Peer: TPeer): TSyncConn;
  end;

  ISyncConnReceiver = interface
    ['{B2C3D4E5-F6A7-4B8C-AD9E-8F706B5C4D3E}']
    function Receive(Conn: TSocket): TSyncConn;
  end;

  TDefaultSyncConnectionFactory = class(TInterfacedObject, ISyncConnInitiator, ISyncConnReceiver)
  private
    FChain: ISyncCacher;
    FPeers: TPeerSet;
    FId: TNodeID;
    FPeerKey: TPrivateKey;
    FMineKey: TPrivateKey;
    function MakeSyncConn(Conn: TSocket): TSyncConn;
  public
    constructor Create(AChain: ISyncCacher; APeers: TPeerSet; const AId: TNodeID; const APeerKey, AMineKey: TPrivateKey);
    function Initiate(Conn: TSocket; Peer: TPeer): TSyncConn;
    function Receive(Conn: TSocket): TSyncConn;
  end;

  TSyncConn = class
  private
    FConn: TSocket;
    FCodec: ICodec;
    FPeer: TPeer;
    FBusy: Integer;
    FSpeed: UInt64;
    FTask: TSyncTask;
    FClosed: Integer;
    FCacher: ISyncCacher;
    FBuf: TBytes;
    FFailed: Integer;
  public
    constructor Create(AConn: TSocket);
    destructor Destroy; override;
    function Download(Task: TSyncTask): Boolean;
    procedure Close;
    function IsBusy: Boolean;
    function Address: string;
  end;

  TDownloadConnPool = class
  private
    FCritSect: TCriticalSection;
    FPeers: TPeerSet;
    FMap: TDictionary<TNodeID, Integer>;
    FConns: TArray<TSyncConn>;
    FBlackList: TDictionary<TNodeID, Int64>;
  public
    constructor Create(APeers: TPeerSet);
    destructor Destroy; override;
    procedure BlockPeer(const Id: TNodeID; Duration: TTimeSpan);
    function ChooseSource(Task: TSyncTask; out P: TPeer; out C: TSyncConn): Boolean;
    procedure AddConn(Conn: TSyncConn);
    procedure DelConn(Conn: TSyncConn);
    procedure Reset;
  end;

implementation

uses System.Threading, V.Net.Codec, V.Crypto, V.Net.PeerError;

{ TDefaultSyncConnectionFactory }

constructor TDefaultSyncConnectionFactory.Create(AChain: ISyncCacher; APeers: TPeerSet; const AId: TNodeID; const APeerKey, AMineKey: TPrivateKey);
begin
  inherited Create;
  FChain := AChain;
  FPeers := APeers;
  FId := AId;
  FPeerKey := APeerKey;
  FMineKey := AMineKey;
end;

function TDefaultSyncConnectionFactory.MakeSyncConn(Conn: TSocket): TSyncConn;
begin
  Result := TSyncConn.Create(Conn);
end;

function TDefaultSyncConnectionFactory.Initiate(Conn: TSocket; Peer: TPeer): TSyncConn;
begin
  // Placeholder logic
  Result := MakeSyncConn(Conn);
  // Full handshake logic would go here
end;

function TDefaultSyncConnectionFactory.Receive(Conn: TSocket): TSyncConn;
begin
  // Placeholder logic
  Result := MakeSyncConn(Conn);
  // Full handshake logic would go here
end;

{ TSyncConn }

constructor TSyncConn.Create(AConn: TSocket);
begin
  inherited Create;
  FConn := AConn;
  FCodec := TTransportFactory.Create(100, TTimeSpan.FromSeconds(10), TTimeSpan.FromSeconds(10)).CreateCodec(AConn);
  SetLength(FBuf, 1024);
end;

destructor TSyncConn.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TSyncConn.Download(Task: TSyncTask): Boolean;
begin
  if TInterlocked.CompareExchange(FBusy, 1, 0) <> 0 then
    raise Exception.Create('Task is already downloading');
  try
    FTask := Task;
    // ... Full download logic placeholder ...
    Result := True;
  finally
    TInterlocked.Exchange(FBusy, 0);
  end;
end;

procedure TSyncConn.Close;
begin
  if TInterlocked.CompareExchange(FClosed, 1, 0) = 0 then
    FConn.Close;
end;

function TSyncConn.IsBusy: Boolean;
begin
  Result := TInterlocked.Read(FBusy) = 1;
end;

function TSyncConn.Address: string;
begin
  Result := FConn.RemoteAddress;
end;

{ TDownloadConnPool }

constructor TDownloadConnPool.Create(APeers: TPeerSet);
begin
  inherited Create;
  FPeers := APeers;
  FCritSect := TCriticalSection.Create;
  FMap := TDictionary<TNodeID, Integer>.Create;
  FBlackList := TDictionary<TNodeID, Int64>.Create;
end;

destructor TDownloadConnPool.Destroy;
begin
  Reset;
  FCritSect.Free;
  FMap.Free;
  FBlackList.Free;
  inherited Destroy;
end;

procedure TDownloadConnPool.BlockPeer(const Id: TNodeID; Duration: TTimeSpan);
begin
  FCritSect.Enter;
  try
    FBlackList.AddOrSetValue(Id, Round(Now * 86400) + Round(Duration.TotalSeconds));
  finally
    FCritSect.Leave;
  end;
end;

function TDownloadConnPool.ChooseSource(Task: TSyncTask; out P: TPeer; out C: TSyncConn): Boolean;
begin
  // Simplified placeholder logic
  Result := False;
  P := nil;
  C := nil;
end;

procedure TDownloadConnPool.AddConn(Conn: TSyncConn);
begin
  FCritSect.Enter;
  try
    if FMap.ContainsKey(Conn.FPeer.Id) then
      raise EPeerError.Create(peAlreadyConnected);
    SetLength(FConns, Length(FConns) + 1);
    FConns[High(FConns)] := Conn;
    FMap.Add(Conn.FPeer.Id, High(FConns));
  finally
    FCritSect.Leave;
  end;
end;

procedure TDownloadConnPool.DelConn(Conn: TSyncConn);
var
  i: Integer;
begin
  Conn.Close;
  FCritSect.Enter;
  try
    if FMap.TryGetValue(Conn.FPeer.Id, i) then
    begin
      FMap.Remove(Conn.FPeer.Id);
      // Simplified removal from array
      if i < High(FConns) then
        FConns[i] := FConns[High(FConns)];
      SetLength(FConns, Length(FConns) - 1);
    end;
  finally
    FCritSect.Leave;
  end;
end;

procedure TDownloadConnPool.Reset;
var
  conns: TArray<TSyncConn>;
  c: TSyncConn;
begin
  FCritSect.Enter;
  try
    FMap.Clear;
    conns := FConns;
    FConns := nil;
  finally
    FCritSect.Leave;
  end;
  for c in conns do
    c.Close;
end;

end.