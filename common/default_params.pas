{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/common/default_params.go
}
unit V.Common.DefaultParams;

interface

uses
  System.SysUtils;

const
  DefaultHTTPHost = 'localhost'; // Default host interface for the HTTP RPC server
  DefaultHTTPPort = 48132;       // Default TCP port for the HTTP RPC server
  DefaultWSHost   = 'localhost'; // Default host interface for the websocket RPC server
  DefaultWSPort   = 31420;       // Default TCP port for the websocket RPC server
  DefaultP2PPort  = 8483;

// DefaultDataDir is $HOME/viteisbest/
function DefaultDataDir: string;

// GoViteTestDataDir is the dir in go-vite/testdata
function GoViteTestDataDir: string;

// HomeDir returns the user's home directory.
function HomeDir: string;

// DefaultHttpEndpoint returns the default HTTP endpoint.
function DefaultHttpEndpoint: string;

// DefaultWSEndpoint returns the default WebSocket endpoint.
function DefaultWSEndpoint: string;

// DefaultIpcFile returns the default IPC file path.
function DefaultIpcFile: string;

implementation

uses
  System.IOUtils;

function DefaultDataDir: string;
var
  home: string;
begin
  home := HomeDir;
  if not home.IsEmpty then
    Result := TPath.Combine(home, 'viteisbest')
  else
    Result := '';
end;

function GoViteTestDataDir: string;
begin
  // NOTE: This is a translation of the Go version which uses runtime source file
  // information. In Delphi, we base this on the executable's location.
  Result := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..', '..', 'testdata'));
end;

function HomeDir: string;
begin
  Result := TPath.GetHomePath;
end;

function DefaultHttpEndpoint: string;
begin
  Result := ':' + IntToStr(DefaultHTTPPort);
end;

function DefaultWSEndpoint: string;
begin
  Result := ':' + IntToStr(DefaultWSPort);
end;

function DefaultIpcFile: string;
begin
  {$IFDEF MSWINDOWS}
  Result := '\\.\pipe\vite.ipc';
  {$ELSE}
  Result := 'vite.ipc';
  {$ENDIF}
end;

end.