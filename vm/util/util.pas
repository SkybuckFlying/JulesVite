{
  This unit is a temporary placeholder for the Go 'vm/util' package.
  It provides minimal constants and types to allow the conversion of dependent units.
}
unit V.VM.Util;

interface

uses
  System.SysUtils, System.Numerics;

var
  AttovPerVite: TBigInteger;

implementation

initialization
  AttovPerVite := TBigInteger.Pow(10, 18);
end.