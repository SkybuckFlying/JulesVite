unit V.Node;

interface

uses
  System.SysUtils,
  V.Common.Types,
  V.Common.Config,
  V.Node.Config,
  V.Wallet,
  V.Vite,
  V.RPC,
  V.RPCAPI,
  V.Pow,
  V.Cmd.Utils.Flock,
  V.Net.Interface,
  V.Ledger.Chain.Interface;

type
  INode = interface
    ['{F6A7B8C9-D0E1-4F80-9182-736E5F403124}']
    procedure Start;
    procedure Stop;
    function GetViteService: IViteService;
    function RpcServer: IServer;
    // other methods
  end;

  TNode = class(TInterfacedObject, INode)
  private
    FConfig: TNodeConfig;
    FLock: IFlock;
    FNet: INet;
    FChain: IChain;
    FRpcServer: IServer;
    FViteService: IViteService;
  public
    constructor Create(cfg: TNodeConfig);
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    function GetViteService: IViteService;
    function RpcServer: IServer;
  end;

function New(cfg: TNodeConfig): TTuple<INode, Error>;

implementation

uses
  V.Node.Errors;

{ TNode }

constructor TNode.Create(cfg: TNodeConfig);
begin
  FConfig := cfg;
  // Initialize other fields here
end;

destructor TNode.Destroy;
begin
  Stop;
  inherited;
end;

procedure TNode.Start;
begin
  // Placeholder implementation for starting the node, which would involve:
  // 1. Acquiring the file lock (FLock.TryLock)
  // 2. Starting the network (FNet.Start)
  // 3. Starting the RPC server (FRpcServer.Start)
  // 4. Starting the Vite service (FViteService.Start)
end;

procedure TNode.Stop;
begin
  // Placeholder implementation for stopping the node in reverse order.
end;

function TNode.GetViteService: IViteService;
begin
  Result := FViteService;
end;

function TNode.RpcServer: IServer;
begin
  Result := FRpcServer;
end;

function New(cfg: TNode_Config.TNodeConfig): TTuple<INode, Error>;
var
  node: TNode;
begin
  try
    node := TNode.Create(cfg);
    Result := TTuple.Create(node as INode, nil);
  except
    on E: Exception do
      Result := TTuple.Create(nil, E);
  end;
end;

end.