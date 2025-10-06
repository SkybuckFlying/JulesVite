{
  This unit is a temporary placeholder for the Go 'common/helper' package.
  It provides minimal constants and types to allow the conversion of dependent units.
}
unit V.Common.Helper;

interface

uses
  System.SysUtils, System.Numerics;

var
  Big0, Big1, Big2, Big10: TBigInteger;

implementation

initialization
  Big0 := TBigInteger.Zero;
  Big1 := TBigInteger.One;
  Big2 := TBigInteger.Create(2);
  Big10 := TBigInteger.Create(10);
end.