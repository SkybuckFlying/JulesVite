{
  This unit is a temporary placeholder for the Go 'curve25519' package.
  It provides a minimal implementation to allow the conversion of dependent units.
}
unit V.Crypto.Curve25519;

interface

uses
  System.SysUtils;

type
  TBytes32 = array[0..31] of Byte;

// ScalarMult multiplies a point by a scalar.
procedure ScalarMult(var Dst, Scalar, Point: TBytes32);

implementation

procedure ScalarMult(var Dst, Scalar, Point: TBytes32);
begin
  // This is a placeholder implementation. A full port of the
  // x/crypto/curve25519 library would be required here.
  FillChar(Dst, SizeOf(Dst), 0);
end;

end.