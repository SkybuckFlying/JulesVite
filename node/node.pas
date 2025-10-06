{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/node/node.go
}
unit V.Node;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs,
  V.Common.Config, V.Node.Config, V.Wallet, V.Vite, V.RPC, V.RPCAPI,
  V.RPCAPI.API.Filters, V.Cmd.Utils.Flock, V.Pow;

type
  TNode = class
  private
    FConfig: TConfig;
    FWalletConfig: TWalletConfig;
    FWalletManager: TWalletManager;
    FViteConfig: TViteConfig;
    FViteServer: TVite;
    FRPCAPIs: TArray<TAPI>;
    FInProcessHandler: TServer;
    FIPCEndpoint: string;
    FIPCListener: TObject; // Placeholder for TSocket/TListener
    FIPCHandler: TServer;
    FHTTPEndpoint: string;
    FHTTPWhitelist: TArray<string>;
    FHTTPListener: TObject;
    FHTTPHandler: TServer;
    FPrivateHTTPEndpoint: string;
    FPrivateHTTPListener: TObject;
    FPrivateHTTPHandler: TServer;
    FWSEndpoint: string;
    FWSListener: TObject;
    FWSHandler: TServer;
    FWSCli: TWebSocketCli;
    FStop: TEvent;
    FLock: TCriticalSection;
    FInstanceDirLock: IReleaser;
    procedure StartWallet;
    procedure StartVite;
    procedure StartRPC;
    procedure StopWallet;
    procedure StopVite;
    procedure StopRPC;
    procedure OpenDataDir;
    // RPC methods
    procedure StartIPC(const Apis: TArray<TAPI>);
    procedure StopIPC;
    procedure StartHTTP(const Endpoint, PrivateEndpoint: string; const Apis: TArray<TAPI>; const Cors, VHosts: TArray<string>; Timeouts: THTTPTimeouts; ExposeAll: Boolean);
    procedure StopHTTP;
    procedure StartWS(const Endpoint: string; const Apis: TArray<TAPI>; const WsOrigins: TArray<string>; ExposeAll: Boolean);
    procedure StopWS;
    procedure StartInProcess(const Apis: TArray<TAPI>);
    procedure StopInProcess;
  public
    constructor Create(AConf: TConfig);
    destructor Destroy; override;
    procedure Prepare;
    procedure Start;
    procedure Stop;
    procedure Wait;
    function Attach: TClient;
    function GetVite: TVite;
    function GetConfig: TConfig;
    function GetViteConfig: TViteConfig;
    function GetWalletManager: TWalletManager;
  end;

implementation

uses System.IOUtils, System.Threading, V.Pow.Remote, V.Node.Errors;

{ TNode }

constructor TNode.Create(AConf: TConfig);
begin
  inherited Create;
  FConfig := AConf;
  FWalletConfig := AConf.MakeWalletConfig;
  FViteConfig := AConf.MakeViteConfig;
  FIPCEndpoint := AConf.IPCEndpoint;
  FHTTPEndpoint := AConf.HTTPEndpoint;
  FWSEndpoint := AConf.WSEndpoint;
  FPrivateHTTPEndpoint := AConf.PrivateHTTPEndpoint;
  FStop := TEvent.Create(nil, True, False, '');
  FLock := TCriticalSection.Create;
end;

destructor TNode.Destroy;
begin
  Stop;
  FStop.Free;
  FLock.Free;
  inherited Destroy;
end;

procedure TNode.Prepare;
begin
  FLock.Enter;
  try
    OpenDataDir;
    if FWalletConfig = nil then
      raise EWalletConfigNil.Create('Wallet config is nil');
    if FWalletManager <> nil then
      raise ENodeRunning.Create('Node already running');
    FWalletManager := TWalletManager.Create(FWalletConfig);
    if FViteServer <> nil then
      raise ENodeRunning.Create('Node already running');
    StartWallet;
    FViteServer := TVite.Create(FViteConfig, FWalletManager);
    V.Pow.Remote.InitRawUrl(FConfig.PowServerUrl);
    V.Pow.Init(FConfig.VMTestParamEnabled);
    FViteServer.Init;
  finally
    FLock.Leave;
  end;
end;

procedure TNode.Start;
begin
  FLock.Enter;
  try
    StartVite;
    StartRPC;
    // monitor.InitNTPChecker(log);
  finally
    FLock.Leave;
  end;
end;

procedure TNode.Stop;
begin
  FLock.Enter;
  try
    FStop.SetEvent;
    StopWallet;
    StopVite;
    StopRPC;
    if Assigned(FInstanceDirLock) then
      FInstanceDirLock.Release;
  finally
    FLock.Leave;
  end;
end;

procedure TNode.Wait;
var
  termChan: TChannel<Boolean>; // Simplified os.Signal
begin
  termChan := TChannel<Boolean>.Create;
  TTask.Run(procedure
    begin
      // Simplified wait logic
      TThread.Sleep(INFINITE);
      termChan.Send(True);
    end);
  TChannel.Select([termChan, FStop.Handle],
    procedure(Value: TValue; Handle: THandle)
    begin
      // Terminate
    end);
  Stop;
end;

function TNode.Attach: TClient;
begin
  FLock.Enter;
  try
    Result := DialInProc(FInProcessHandler);
  finally
    FLock.Leave;
  end;
end;

procedure TNode.StartInProcess(const Apis: TArray<TAPI>);
var
  handler: TServer;
  api: TAPI;
begin
  handler := TServer.Create;
  for api in Apis do
    handler.RegisterName(api.Namespace, api.Service);
  FInProcessHandler := handler;
end;

procedure TNode.StopInProcess;
begin
  if FInProcessHandler <> nil then
  begin
    FInProcessHandler.Stop;
    FInProcessHandler := nil;
  end;
end;

procedure TNode.StartIPC(const Apis: TArray<TAPI>);
begin
  if FIPCEndpoint = '' then Exit;
  // FIPCListener, FIPCHandler := V.RPC.StartIPCEndpoint(FIPCEndpoint, Apis);
  // Log info
end;

procedure TNode.StopIPC;
begin
  if FIPCListener <> nil then
  begin
    // FIPCListener.Close;
    FIPCListener := nil;
  end;
  if FIPCHandler <> nil then
  begin
    FIPCHandler.Stop;
    FIPCHandler := nil;
  end;
end;

procedure TNode.StartHTTP(const Endpoint, PrivateEndpoint: string; const Apis: TArray<TAPI>; const Cors, VHosts: TArray<string>; Timeouts: THTTPTimeouts; ExposeAll: Boolean);
begin
  if Endpoint = '' then Exit;
  // FHTTPListener, FHTTPHandler, FPrivateHTTPListener, FPrivateHTTPHandler := V.RPC.StartHTTPEndpoint(...);
  FHTTPEndpoint := Endpoint;
end;

procedure TNode.StopHTTP;
begin
  if FHTTPListener <> nil then
  begin
    // FHTTPListener.Close;
    FHTTPListener := nil;
  end;
  if FHTTPHandler <> nil then
  begin
    FHTTPHandler.Stop;
    FHTTPHandler := nil;
  end;
  // Stop private http as well
end;

procedure TNode.StartWS(const Endpoint: string; const Apis: TArray<TAPI>; const WsOrigins: TArray<string>; ExposeAll: Boolean);
begin
  if Endpoint = '' then Exit;
  // FWSListener, FWSHandler := V.RPC.StartWSEndpoint(...);
  FWSEndpoint := Endpoint;
end;

procedure TNode.StopWS;
begin
  if FWSListener <> nil then
  begin
    // FWSListener.Close;
    FWSListener := nil;
  end;
  if FWSHandler <> nil then
  begin
    FWSHandler.Stop;
    FWSHandler := nil;
  end;
  if FWSCli <> nil then
    FWSCli.Close;
end;

function TNode.GetVite: TVite; begin Result := FViteServer; end;
function TNode.GetConfig: TConfig; begin Result := FConfig; end;
function TNode.GetViteConfig: TViteConfig; begin Result := FViteConfig; end;
function TNode.GetWalletManager: TWalletManager; begin Result := FWalletManager; end;

procedure TNode.StartWallet;
begin
  FWalletManager.Start;
  if FConfig.EntropyStorePath <> '' then
  begin
    FWalletManager.AddEntropyStore(FConfig.EntropyStorePath);
    FWalletManager.Unlock(FConfig.EntropyStorePath, FConfig.EntropyStorePassword);
  end;
end;

procedure TNode.StartVite;
begin
  FViteServer.Start;
end;

procedure TNode.StartRPC;
var
  apis, publicApis, customApis: TArray<TAPI>;
begin
  if FConfig.SubscribeEnabled then
  begin
    Es := NewEventSystem(FViteServer);
    Es.Start;
  end;
  V.RPCAPI.Init(FConfig.DataDir, FConfig.LogLevel, FConfig.TestTokenHexPrivKey, FConfig.TestTokenTti, FConfig.NetID, FConfig.TxDexEnable);
  publicApis := GetPublicApis(FViteServer);
  customApis := GetApis(FViteServer, FConfig.PublicModules);
  apis := MergeApis(publicApis, customApis);
  StartInProcess(apis);
  if FConfig.IPCEnabled then
    StartIPC(apis);
  if FConfig.RPCEnabled then
    StartHTTP(FHTTPEndpoint, FPrivateHTTPEndpoint, apis, FConfig.HTTPCors, FConfig.HttpVirtualHosts, THTTPTimeouts.Create, FConfig.HttpExposeAll);
  if FConfig.WSEnabled then
    StartWS(FWSEndpoint, apis, FConfig.WSOrigins, FConfig.WSExposeAll);
  if FConfig.DashboardTargetURL <> '' then
  begin
    // ... WebSocket client logic ...
  end;
end;

procedure TNode.StopWallet;
begin
  if FWalletManager = nil then
    raise ENodeStopped.Create('Node not started');
  FWalletManager.Stop;
end;

procedure TNode.StopVite;
begin
  if FViteServer = nil then
    raise ENodeStopped.Create('Node not started');
  FViteServer.Stop;
end;

procedure TNode.StopRPC;
begin
  StopWS;
  StopHTTP;
  StopIPC;
  if Assigned(Es) then
    Es.Stop;
end;

procedure TNode.OpenDataDir;
begin
  if FConfig.DataDir = '' then Exit;
  TDirectory.CreateDirectory(FConfig.DataDir);
  FInstanceDirLock := V.Cmd.Utils.Flock.New(TPath.Combine(FConfig.DataDir, 'LOCK'));
  TDirectory.CreateDirectory(FWalletConfig.DataDir);
end;

end.