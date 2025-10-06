unit V.Common.Math.Big;

interface

uses
  System.SysUtils;

type
  TBigInt = record
    // This is a placeholder for Go's big.Int.
    // It will be replaced with a proper big number library implementation.
  end;

  function NewInt(val: Int64): TBigInt;

implementation

function NewInt(val: Int64): TBigInt;
begin
  // Placeholder implementation
end;

end.