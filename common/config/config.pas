{
  This unit is a temporary placeholder for the Go 'common/config' package.
  It provides minimal type definitions to allow the conversion of dependent units.
}
unit V.Common.Config;

interface

uses
  System.SysUtils, V.Common.Types, V.Crypto.Ed25519;

type
  TChainConfig = record
    LedgerGcRetain: UInt64;
    LedgerGc: Boolean;
    OpenPlugins: Boolean;
    VmLogWhiteList: TArray<TAddress>;
    VmLogAll: Boolean;
  end;

  TProducerConfig = record
    Producer: Boolean;
    Coinbase: string;
    EntropyStorePath: string;
    VirtualSnapshotVerifier: Boolean;
  end;

  TNetConfig = record
    Single: Boolean;
    Name: string;
    NetID: Integer;
    ListenInterface: string;
    Port: Integer;
    FilePort: Integer;
    PublicAddress: string;
    FilePublicAddress: string;
    DataDir: string;
    PeerKey: string;
    Discover: Boolean;
    BootNodes: TArray<string>;
    BootSeeds: TArray<string>;
    StaticNodes: TArray<string>;
    MaxPeers: Integer;
    MaxInboundRatio: Integer;
    MinPeers: Integer;
    MaxPendingPeers: Integer;
    ForwardStrategy: string;
    AccessControl: string;
    AccessAllowKeys: TArray<string>;
    AccessDenyKeys: TArray<string>;
    BlackBlockHashList: TArray<string>;
    WhiteBlockList: TArray<string>;
    MineKey: TPrivateKey;
  end;

  TWalletConfig = record
    DataDir: string;
    MaxSearchIndex: UInt32;
  end;

  TVmConfig = record
    IsVmTest: Boolean;
    IsUseVmTestParam: Boolean;
    IsUseQuotaTestParam: Boolean;
    IsVmDebug: Boolean;
  end;

  TSubscribeConfig = record
    IsSubscribe: Boolean;
  end;

  TNodeRewardConfig = record
    RewardAddr: string;
    Name: string;
  end;

  TGenesisConfig = record
    // Placeholder
  end;

  TViteConfig = record
    Producer: TProducerConfig;
    Chain: TChainConfig;
    Vm: TVmConfig;
    Subscribe: TSubscribeConfig;
    Net: TNetConfig;
    NodeReward: TNodeRewardConfig;
    Genesis: TGenesisConfig;
    DataDir: string;
    LogLevel: string;
  end;

const
  DefaultNetDirName = 'net';

function MakeGenesisConfig(const GenesisFile: string): TGenesisConfig;

implementation

uses System.IOUtils;

function HomeDir: string;
begin
  Result := TPath.GetHomePath;
end;

function DefaultDataDir: string;
var
  home: string;
begin
  home := HomeDir;
  if home <> '' then
  begin
    {$IFDEF MSWINDOWS}
    Result := TPath.Combine(home, 'AppData');
    Result := TPath.Combine(Result, 'Roaming');
    Result := TPath.Combine(Result, 'GVite');
    {$ENDIF}
    {$IFDEF MACOS}
    Result := TPath.Combine(home, 'Library');
    Result := TPath.Combine(Result, 'GVite');
    {$ENDIF}
    {$IFDEF LINUX}
    Result := TPath.Combine(home, '.gvite');
    {$ENDIF}
  end
  else
    Result := '';
end;

function MakeGenesisConfig(const GenesisFile: string): TGenesisConfig;
begin
  // Placeholder logic
end;

end.