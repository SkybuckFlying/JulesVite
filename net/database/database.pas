{
  This unit is a temporary placeholder for the Go 'net/database' package.
  It provides a minimal TDB class to allow the conversion of dependent units.
}
unit V.Net.Database;

interface

uses
  System.SysUtils, V.Net.VNode, V.Common.Types;

type
  // TDB is a placeholder for the network database.
  TDB = class
  public
    constructor Create(const Path: string; Version: Integer; const ID: TNodeID);
    function ReadMarkNodes(Count: Integer): TNodeArray;
    procedure StoreNode(Node: PNode);
    procedure StoreMark(const ID: TNodeID; Weight: Int64);
  end;

implementation

{ TDB }

constructor TDB.Create(const Path: string; Version: Integer; const ID: TNodeID);
begin
  // Placeholder
end;

function TDB.ReadMarkNodes(Count: Integer): TNodeArray;
begin
  // Placeholder
  Result := nil;
end;

procedure TDB.StoreNode(Node: PNode);
begin
  // Placeholder
end;

procedure TDB.StoreMark(const ID: TNodeID; Weight: Int64);
begin
  // Placeholder
end;

end.