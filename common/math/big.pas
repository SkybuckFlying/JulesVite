{
  Copyright 2017 The go-ethereum Authors
  This file is part of the go-ethereum library.

  The go-ethereum library is free software: you can redistribute it and/or modify
  it under the terms of the GNU Lesser General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  The go-ethereum library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  GNU Lesser General Public License for more details.

  You should have received chain copy of the GNU Lesser General Public License
  along with the go-ethereum library. If not, see <http://www.gnu.org/licenses/>.

  This file is a translation of the original Go source file:
  https://github.com/ethereum/go-ethereum/blob/master/common/math/big.go
}
unit V.Common.Math.Big;

interface

uses
  System.SysUtils, System.Numerics, System.StrUtils;

var
  tt255, tt256, tt256m1, tt63, MaxBig256, MaxBig63: TBigInteger;

const
  MaxBigIntLen = 256;
  // number of bits in a big.Word, assuming 64-bit platform for Delphi
  wordBits = 64;
  // number of bytes in a big.Word
  wordBytes = wordBits div 8;

type
  // HexOrDecimal256 marshals TBigInteger as hex or decimal.
  HexOrDecimal256 = type TBigInteger;

  // THexOrDecimal256Helper provides methods for the HexOrDecimal256 type.
  THexOrDecimal256Helper = record helper for HexOrDecimal256
  public
    function UnmarshalText(const input: TBytes): Boolean;
    function MarshalText: TBytes;
  end;

// ParseBig256 parses s as a 256 bit integer in decimal or hexadecimal syntax.
function TryParseBig256(const s: string; out Value: TBigInteger): Boolean;

// MustParseBig256 parses s as a 256 bit big integer and panics if the string is invalid.
function MustParseBig256(const s: string): TBigInteger;

// BigPow returns a ** b as a big integer.
function BigPow(a, b: Int64): TBigInteger;

// BigMax returns the larger of x or y.
function BigMax(x, y: TBigInteger): TBigInteger;

// BigMin returns the smaller of x or y.
function BigMin(x, y: TBigInteger): TBigInteger;

// PaddedBigBytes encodes a big integer as a big-endian byte slice of at least n bytes.
function PaddedBigBytes(const bigint: TBigInteger; n: Integer): TBytes;

// ReadBits encodes the absolute value of bigint as big-endian bytes.
procedure ReadBits(const bigint: TBigInteger; buf: TBytes);

// U256 encodes as a 256 bit two's complement number.
function U256(x: TBigInteger): TBigInteger;

// S256 interprets x as a two's complement number.
function S256(x: TBigInteger): TBigInteger;

// Exp implements exponentiation by squaring.
function Exp(base, exponent: TBigInteger): TBigInteger;

implementation

{ THexOrDecimal256Helper }

function THexOrDecimal256Helper.UnmarshalText(const input: TBytes): Boolean;
var
  s: string;
  bigint: TBigInteger;
begin
  s := TEncoding.UTF8.GetString(input);
  Result := TryParseBig256(s, bigint);
  if Result then
    Self := HexOrDecimal256(bigint);
end;

function THexOrDecimal256Helper.MarshalText: TBytes;
var
  s: string;
begin
  s := '0x' + Self.ToHexString;
  Result := TEncoding.UTF8.GetBytes(s);
end;

function TryParseBig256(const s: string; out Value: TBigInteger): Boolean;
var
  s_trimmed: string;
begin
  s_trimmed := s.Trim;
  if s_trimmed = '' then
  begin
    Value := TBigInteger.Zero;
    Result := True;
    Exit;
  end;

  if s_trimmed.StartsWith('0x', True) then
    Result := TBigInteger.TryParse(s_trimmed.Substring(2), System.Globalization.NumberStyles.HexNumber, nil, Value)
  else
    Result := TBigInteger.TryParse(s_trimmed, Value);

  if Result and (Value.BitLength > 256) then
    Result := False;
end;

function MustParseBig256(const s: string): TBigInteger;
begin
  if not TryParseBig256(s, Result) then
    raise EConvertError.CreateFmt('invalid 256 bit integer: "%s"', [s]);
end;

function BigPow(a, b: Int64): TBigInteger;
var
  base: TBigInteger;
begin
  base := TBigInteger.Create(a);
  Result := TBigInteger.Pow(base, b);
end;

function BigMax(x, y: TBigInteger): TBigInteger;
begin
  if x.CompareTo(y) < 0 then
    Result := y
  else
    Result := x;
end;

function BigMin(x, y: TBigInteger): TBigInteger;
begin
  if x.CompareTo(y) > 0 then
    Result := y
  else
    Result := x;
end;

function PaddedBigBytes(const bigint: TBigInteger; n: Integer): TBytes;
var
  bytes: TBytes;
  len_bytes: Integer;
begin
  bytes := bigint.ToByteArray(True); // big-endian
  len_bytes := Length(bytes);
  if len_bytes >= n then
    Result := bytes
  else
  begin
    SetLength(Result, n);
    System.Buffer.BlockCopy(bytes, 0, Result, n - len_bytes, len_bytes);
  end;
end;

procedure ReadBits(const bigint: TBigInteger; buf: TBytes);
var
  bytes: TBytes;
  len_bytes, len_buf, offset: Integer;
begin
  bytes := bigint.ToByteArray(True); // big-endian
  len_bytes := Length(bytes);
  len_buf := Length(buf);
  if len_bytes > len_buf then
    offset := len_bytes - len_buf
  else
    offset := 0;

  System.Buffer.BlockCopy(bytes, offset, buf, 0, Min(len_bytes, len_buf));
end;

function U256(x: TBigInteger): TBigInteger;
begin
  Result := x and tt256m1;
end;

function S256(x: TBigInteger): TBigInteger;
begin
  if x.CompareTo(tt255) < 0 then
    Result := x
  else
    Result := x - tt256;
end;

function Exp(base, exponent: TBigInteger): TBigInteger;
var
  res, tempBase: TBigInteger;
  i: Integer;
begin
  res := TBigInteger.One;
  tempBase := base;
  for i := 0 to exponent.BitLength - 1 do
  begin
    if exponent.TestBit(i) then
      res := U256(res * tempBase);
    tempBase := U256(tempBase * tempBase);
  end;
  Result := res;
end;

initialization
  tt255 := TBigInteger.Pow(2, 255);
  tt256 := TBigInteger.Pow(2, 256);
  tt256m1 := tt256 - TBigInteger.One;
  tt63 := TBigInteger.Pow(2, 63);
  MaxBig63 := tt63 - TBigInteger.One;
  MaxBig256 := tt256m1;
end.