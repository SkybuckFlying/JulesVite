{
  This unit is a temporary placeholder for the Go 'rpc' package.
  It provides minimal definitions for the RPC framework to allow
  the conversion of dependent units.
}
unit V.RPC;

interface

uses
  System.SysUtils, System.Classes;

type
  // TAPI describes a single API provided by a module.
  TAPI = record
    Namespace: string;
    Service: TObject; // Placeholder for the API service object
  end;

  // TServer is the RPC server.
  TServer = class
  public
    procedure Stop;
    procedure RegisterName(const Name: string; const Service: TObject);
  end;

  // TClient is the RPC client.
  TClient = class
  public
    // Placeholder methods
  end;

  // TWebSocketCli is the WebSocket client.
  TWebSocketCli = class
  public
    procedure Close;
  end;

  // THTTPTimeouts configures HTTP server timeouts.
  THTTPTimeouts = record
    // Placeholder fields
  end;

// StartIPCEndpoint starts the IPC endpoint.
function StartIPCEndpoint(const Endpoint: string; const Apis: TArray<TAPI>): TObject; // Returns TListener, TServer
// StartHTTPEndpoint starts the HTTP endpoint.
function StartHTTPEndpoint(const Endpoint, PrivateEndpoint: string; const Apis: TArray<TAPI>; const Modules, Cors, VHosts: TArray<string>; Timeouts: THTTPTimeouts; ExposeAll: Boolean): TObject; // Returns TListener, TServer, TListener, TServer
// StartWSEndpoint starts the WebSocket endpoint.
function StartWSEndpoint(const Endpoint: string; const Apis: TArray<TAPI>; const Modules, WsOrigins: TArray<string>; ExposeAll: Boolean): TObject; // Returns TListener, TServer
// StartWSCliEndpoint starts a WebSocket client endpoint.
function StartWSCliEndpoint(const Url: string; const Apis: TArray<TAPI>; ExposeAll: Boolean): TWebSocketCli;
// DialInProc dials an in-process RPC server.
function DialInProc(Handler: TServer): TClient;

implementation

{ TServer }
procedure TServer.Stop;
begin
  // Placeholder
end;
procedure TServer.RegisterName(const Name: string; const Service: TObject);
begin
  // Placeholder
end;

{ TWebSocketCli }
procedure TWebSocketCli.Close;
begin
  // Placeholder
end;

function StartIPCEndpoint(const Endpoint: string; const Apis: TArray<TAPI>): TObject;
begin
  Result := nil; // Placeholder
end;

function StartHTTPEndpoint(const Endpoint, PrivateEndpoint: string; const Apis: TArray<TAPI>; const Modules, Cors, VHosts: TArray<string>; Timeouts: THTTPTimeouts; ExposeAll: Boolean): TObject;
begin
  Result := nil; // Placeholder
end;

function StartWSEndpoint(const Endpoint: string; const Apis: TArray<TAPI>; const Modules, WsOrigins: TArray<string>; ExposeAll: Boolean): TObject;
begin
  Result := nil; // Placeholder
end;

function StartWSCliEndpoint(const Url: string; const Apis: TArray<TAPI>; ExposeAll: Boolean): TWebSocketCli;
begin
  Result := TWebSocketCli.Create; // Placeholder
end;

function DialInProc(Handler: TServer): TClient;
begin
  Result := TClient.Create; // Placeholder
end;

end.