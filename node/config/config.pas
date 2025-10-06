{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/node/config/config.go
}
unit V.Node.Config;

interface

uses
  System.SysUtils, System.Classes,
  V.Common.Types, V.Common.Config, V.Crypto.Ed25519;

type
  TConfig = record
    NetSelect: string;
    DataDir: string;
    KeyStoreDir: string;
    LedgerGcRetain: UInt64;
    LedgerGc: PBoolean;
    OpenPlugins: PBoolean;
    VmLogWhiteList: TArray<TAddress>;
    VmLogAll: PBoolean;
    GenesisFile: string;
    Single: Boolean;
    ListenInterface: string;
    Port: Integer;
    FilePort: Integer;
    PublicAddress: string;
    FilePublicAddress: string;
    Identity: string;
    NetID: Integer;
    PeerKey: string;
    Discover: Boolean;
    MaxPeers: Integer;
    MinPeers: Integer;
    MaxInboundRatio: Integer;
    MaxPendingPeers: Integer;
    BootNodes: TArray<string>;
    BootSeeds: TArray<string>;
    StaticNodes: TArray<string>;
    AccessControl: string;
    AccessAllowKeys: TArray<string>;
    AccessDenyKeys: TArray<string>;
    BlackBlockHashList: TArray<string>;
    WhiteBlockList: TArray<string>;
    ForwardStrategy: string;
    EntropyStorePath: string;
    EntropyStorePassword: string;
    CoinBase: string;
    MinerEnabled: Boolean;
    RPCEnabled: Boolean;
    IPCEnabled: Boolean;
    WSEnabled: Boolean;
    TxDexEnable: PBoolean;
    IPCPath: string;
    HttpHost: string;
    HttpPort: Integer;
    HttpVirtualHosts: TArray<string>;
    WSHost: string;
    WSPort: Integer;
    PrivateHttpPort: Integer;
    HTTPCors: TArray<string>;
    WSOrigins: TArray<string>;
    PublicModules: TArray<string>;
    WSExposeAll: Boolean;
    HttpExposeAll: Boolean;
    TestTokenHexPrivKey: string;
    TestTokenTti: string;
    PowServerUrl: string;
    LogLevel: string;
    ErrorLogDir: string;
    VMTestEnabled: Boolean;
    VMTestParamEnabled: Boolean;
    QuotaTestParamEnabled: Boolean;
    VMDebug: Boolean;
    SubscribeEnabled: Boolean;
    DashboardTargetURL: string;
    RewardAddr: string;
    MetricsEnable: PBoolean;
    InfluxDBEnable: PBoolean;
    InfluxDBEndpoint: PString;
    InfluxDBDatabase: PString;
    InfluxDBUsername: PString;
    InfluxDBPassword: PString;
    InfluxDBHostTag: PString;
    function MakeWalletConfig: TWalletConfig;
    function MakeViteConfig: TViteConfig;
    function MakeNetConfig: TNetConfig;
    function MakeRewardConfig: TNodeRewardConfig;
    function MakeVmConfig: TVmConfig;
    function MakeSubscribeConfig: TSubscribeConfig;
    function MakeMinerConfig: TProducerConfig;
    function MakeChainConfig: TChainConfig;
    function HTTPEndpoint: string;
    function WSEndpoint: string;
    function PrivateHTTPEndpoint: string;
    procedure SetPrivateKey(const privateKey: string);
    function GetPrivateKey: TPrivateKey;
    function IPCEndpoint: string;
    function RunLogDir: string;
    procedure DataDirPathAbs;
    procedure ParseFromFile(const filename: string);
  end;

implementation

uses System.JSON, System.IOUtils, V.Common.DefaultParams;

function TConfig.MakeWalletConfig: TWalletConfig;
begin
  Result.DataDir := Self.KeyStoreDir;
end;

function TConfig.MakeViteConfig: TViteConfig;
begin
  Result.Chain := Self.MakeChainConfig;
  Result.Producer := Self.MakeMinerConfig;
  Result.DataDir := Self.DataDir;
  Result.Net := Self.MakeNetConfig;
  Result.Vm := Self.MakeVmConfig;
  Result.Subscribe := Self.MakeSubscribeConfig;
  Result.NodeReward := Self.MakeRewardConfig;
  Result.Genesis := MakeGenesisConfig(Self.GenesisFile);
  Result.LogLevel := Self.LogLevel;
end;

function TConfig.MakeNetConfig: TNetConfig;
begin
  Result.DataDir := TPath.Combine(Self.DataDir, DefaultNetDirName);
  Result.Single := Self.Single;
  Result.Name := Self.Identity;
  Result.NetID := Self.NetID;
  Result.ListenInterface := Self.ListenInterface;
  Result.Port := Self.Port;
  Result.FilePort := Self.FilePort;
  Result.PublicAddress := Self.PublicAddress;
  Result.FilePublicAddress := Self.FilePublicAddress;
  Result.PeerKey := Self.PeerKey;
  Result.Discover := Self.Discover;
  Result.BootNodes := Self.BootNodes;
  Result.BootSeeds := Self.BootSeeds;
  Result.StaticNodes := Self.StaticNodes;
  Result.MaxPeers := Self.MaxPeers;
  Result.MaxInboundRatio := Self.MaxInboundRatio;
  Result.MinPeers := Self.MinPeers;
  Result.MaxPendingPeers := Self.MaxPendingPeers;
  Result.ForwardStrategy := Self.ForwardStrategy;
  Result.AccessControl := Self.AccessControl;
  Result.AccessAllowKeys := Self.AccessAllowKeys;
  Result.AccessDenyKeys := Self.AccessDenyKeys;
  Result.BlackBlockHashList := Self.BlackBlockHashList;
  Result.WhiteBlockList := Self.WhiteBlockList;
  // Result.MineKey := nil; // Requires conversion from hex
end;

function TConfig.MakeRewardConfig: TNodeRewardConfig;
begin
  Result.RewardAddr := Self.RewardAddr;
  Result.Name := Self.Identity;
end;

function TConfig.MakeVmConfig: TVmConfig;
begin
  Result.IsVmTest := Self.VMTestEnabled;
  Result.IsUseVmTestParam := Self.VMTestParamEnabled;
  Result.IsUseQuotaTestParam := Self.QuotaTestParamEnabled;
  Result.IsVmDebug := Self.VMDebug;
end;

function TConfig.MakeSubscribeConfig: TSubscribeConfig;
begin
  Result.IsSubscribe := Self.SubscribeEnabled;
end;

function TConfig.MakeMinerConfig: TProducerConfig;
begin
  Result.Producer := Self.MinerEnabled;
  Result.Coinbase := Self.CoinBase;
  Result.EntropyStorePath := Self.EntropyStorePath;
  Result.VirtualSnapshotVerifier := False;
  // Result.Parse; // Placeholder
end;

function TConfig.MakeChainConfig: TChainConfig;
begin
  if Assigned(Self.LedgerGc) then
    Result.LedgerGc := Self.LedgerGc^
  else
    Result.LedgerGc := True;
  if Assigned(Self.OpenPlugins) then
    Result.OpenPlugins := Self.OpenPlugins^
  else
    Result.OpenPlugins := False;
  if Assigned(Self.VmLogAll) then
    Result.VmLogAll := Self.VmLogAll^
  else
    Result.VmLogAll := False;
  Result.LedgerGcRetain := Self.LedgerGcRetain;
  Result.VmLogWhiteList := Self.VmLogWhiteList;
end;

function TConfig.HTTPEndpoint: string;
begin
  if HttpHost = '' then Exit('');
  Result := Format('%s:%d', [HttpHost, HttpPort]);
end;

function TConfig.WSEndpoint: string;
begin
  if WSHost = '' then Exit('');
  Result := Format('%s:%d', [WSHost, WSPort]);
end;

function TConfig.PrivateHTTPEndpoint: string;
begin
  if PrivateHttpPort = 0 then Exit('');
  Result := Format('%s:%d', [V.Common.DefaultParams.DefaultHTTPHost, PrivateHttpPort]);
end;

procedure TConfig.SetPrivateKey(const privateKey: string);
begin
  Self.PeerKey := privateKey;
end;

function TConfig.GetPrivateKey: TPrivateKey;
var
  keyBytes: TBytes;
begin
  // Placeholder for hex decoding
  // keyBytes := HexToBytes(Self.PeerKey);
  // Move(keyBytes[0], Result, SizeOf(TPrivateKey));
end;

function TConfig.IPCEndpoint: string;
begin
  if IPCPath = '' then Exit('');
  {$IFDEF MSWINDOWS}
  if Pos('\\.\pipe\', IPCPath) = 1 then
    Exit(IPCPath)
  else
    Exit('\\.\pipe\' + IPCPath);
  {$ENDIF}
  if TPath.GetFileName(IPCPath) = IPCPath then
  begin
    if DataDir = '' then
      Result := TPath.Combine(TPath.GetTempPath, IPCPath)
    else
      Result := TPath.Combine(DataDir, IPCPath);
  end
  else
    Result := IPCPath;
end;

function TConfig.RunLogDir: string;
begin
  Result := TPath.Combine(Self.DataDir, 'runlog');
  Result := TPath.Combine(Result, FormatDateTime('yyyy-mm-dd"T"hh-nn', Now));
end;

procedure TConfig.DataDirPathAbs;
begin
  if DataDir <> '' then
    DataDir := TPath.GetFullPath(DataDir);
  if KeyStoreDir <> '' then
    KeyStoreDir := TPath.GetFullPath(KeyStoreDir);
end;

procedure TConfig.ParseFromFile(const filename: string);
var
  jsonString: string;
  jsonObj: TJSONObject;
begin
  jsonString := TFile.ReadAllText(filename);
  jsonObj := TJSONObject.ParseJSONValue(jsonString) as TJSONObject;
  try
    // Manual JSON parsing would be required here for each field
    // For example: Self.NetSelect := jsonObj.GetValue<string>('NetSelect');
  finally
    jsonObj.Free;
  end;
end;

end.