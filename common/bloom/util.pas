{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/common/bloom/util.go
}
unit V.Common.Bloom.Util;

interface

uses
  System.SysUtils, V.Hash.FNV;

// OptimalM calculates the optimal Bloom filter size.
function OptimalM(N: Cardinal; FpRate: Double): Cardinal;

// OptimalK calculates the optimal number of hash functions.
function OptimalK(FpRate: Double): Cardinal;

// HashInternal returns the upper and lower base hash values.
procedure HashInternal(const Data: TBytes; const Hash: IHash64; out Lower, Upper: UInt32);

implementation

uses
  System.Math, System.Net.Sockets;

const
  FillRatio = 0.5;
var
  FillRatioX: Double = 0;

function OptimalM(N: Cardinal; FpRate: Double): Cardinal;
var
  Base, R: Double;
begin
  if FillRatioX = 0 then
    FillRatioX := System.Math.Log(FillRatio) * System.Math.Log(1 - FillRatio);

  Base := Abs(System.Math.Log(FpRate)) / FillRatioX;
  R := N * Base;
  Result := Cardinal(Ceil(R));
end;

function OptimalK(FpRate: Double): Cardinal;
begin
  Result := Cardinal(Ceil(Log2(1 / FpRate)));
end;

procedure HashInternal(const Data: TBytes; const Hash: IHash64; out Lower, Upper: UInt32);
var
  Sum: TBytes;
begin
  Hash.Write(Data);
  Sum := Hash.Sum(nil);
  Hash.Reset;
  // Note: Go's binary.BigEndian.Uint32 is equivalent to ntohl in Delphi
  // when reading from a byte array.
  Upper := ntohl(PUInt32(@Sum[0])^);
  Lower := ntohl(PUInt32(@Sum[4])^);
end;

end.