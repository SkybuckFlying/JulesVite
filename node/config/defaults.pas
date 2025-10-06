{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/node/config/defaults.go
}
unit V.Node.Config.Defaults;

interface

uses
  System.SysUtils, V.Common.Config, V.Node.Config;

var
  DefaultNodeConfig: TConfig;

function DefaultDataDir: string;

implementation

uses System.IOUtils, V.Common.DefaultParams;

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

initialization
  DefaultNodeConfig.IPCPath := 'gvite.ipc';
  DefaultNodeConfig.DataDir := DefaultDataDir;
  DefaultNodeConfig.KeyStoreDir := DefaultDataDir;
  DefaultNodeConfig.HttpPort := V.Common.DefaultParams.DefaultHTTPPort;
  DefaultNodeConfig.WSPort := V.Common.DefaultParams.DefaultWSPort;
  DefaultNodeConfig.LogLevel := 'info';
  DefaultNodeConfig.HTTPCors := ['*'];
  DefaultNodeConfig.WSOrigins := ['*'];
  DefaultNodeConfig.WSExposeAll := False;
  DefaultNodeConfig.HttpExposeAll := False;
  // Values from V.Common.Config would be used here
  // DefaultNodeConfig.Single := V.Common.Config.DefaultSingle;
  // ... and so on for the rest of the fields
end.