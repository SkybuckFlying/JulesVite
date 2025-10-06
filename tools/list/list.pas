{
  This unit is a temporary placeholder for the Go 'tools/list' package.
  It provides a minimal TList implementation to allow the conversion of dependent units.
}
unit V.Tools.List;

interface

uses
  System.SysUtils, System.Generics.Collections;

type
  // TList is a placeholder for the list.List structure.
  TList = class(TQueue<TObject>)
  public
    procedure Append(Item: TObject);
    function Shift: TObject;
    function Size: Integer;
  end;

implementation

{ TList }

procedure TList.Append(Item: TObject);
begin
  Self.Enqueue(Item);
end;

function TList.Shift: TObject;
begin
  if Self.Count > 0 then
    Result := Self.Dequeue
  else
    Result := nil;
end;

function TList.Size: Integer;
begin
  Result := Self.Count;
end;

end.