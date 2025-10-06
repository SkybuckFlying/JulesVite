{
  This unit is a temporary placeholder for the Go 'vm/intpool' package.
  It provides a minimal TIntPool class to allow the conversion of dependent units.
}
unit V.VM.IntPool;

interface

uses
  System.SysUtils, System.Numerics;

type
  TIntPool = class
  public
    function Get: TBigInteger;
    function GetZero: TBigInteger;
    procedure Put(var Ints: array of TBigInteger);
  end;

implementation

{ TIntPool }

function TIntPool.Get: TBigInteger;
begin
  Result := TBigInteger.Zero;
end;

function TIntPool.GetZero: TBigInteger;
begin
  Result := TBigInteger.Zero;
end;

procedure TIntPool.Put(var Ints: array of TBigInteger);
var
  i: Integer;
begin
  for i := 0 to High(Ints) do
  begin
    // In a real pool, we would return the object to the pool.
    // For this placeholder, we do nothing.
  end;
end;

end.