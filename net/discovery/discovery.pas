{
  This unit is a temporary placeholder for the Go 'net/discovery' package.
  It provides a minimal implementation to allow the conversion of dependent units.
}
unit V.Net.Discovery;

interface

uses
  System.SysUtils, V.Crypto.Ed25519, V.Net.VNode, V.Net.Database;

type
  TNodeFunc = procedure(Node: PNode);

  ISubscriber = interface
    ['{A1B2C3D4-E5F6-4A8B-9C8D-7E6F5A4B3C2D}']
    function Sub(Fn: TNodeFunc): Integer;
    procedure UnSub(Id: Integer);
  end;

  IFinder = interface
    ['{B2C3D4E5-F6A7-4B8C-AD9E-8F706B5C4D3E}']
    // Placeholder for finder interface methods
  end;

  TDiscovery = class
  public
    constructor Create(const Key: TPrivateKey; Node: PNode; const BootNodes, BootSeeds: array of string; const ListenAddr: string; DB: TDB);
    procedure Start;
    procedure Stop;
    procedure SetFinder(Finder: IFinder);
    function Nodes: TNodeArray;
  end;

implementation

{ TDiscovery }

constructor TDiscovery.Create(const Key: TPrivateKey; Node: PNode; const BootNodes, BootSeeds: array of string; const ListenAddr: string; DB: TDB);
begin
  // Placeholder
end;

procedure TDiscovery.Start;
begin
  // Placeholder
end;

procedure TDiscovery.Stop;
begin
  // Placeholder
end;

procedure TDiscovery.SetFinder(Finder: IFinder);
begin
  // Placeholder
end;

function TDiscovery.Nodes: TNodeArray;
begin
  Result := nil; // Placeholder
end;

end.