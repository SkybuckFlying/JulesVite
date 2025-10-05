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
  https://github.com/ethereum/go-ethereum/blob/master/common/math/integer.go
}
unit V.Common.Math.Integer;

interface

uses
  System.SysUtils, System.Character;

const
  MaxInt8   = 1 shl 7 - 1;
  MinInt8   = -1 shl 7;
  MaxInt16  = 1 shl 15 - 1;
  MinInt16  = -1 shl 15;
  MaxInt32  = 1 shl 31 - 1;
  MinInt32  = -1 shl 31;
  MaxInt64  = 1 shl 63 - 1;
  MinInt64  = -1 shl 63;
  MaxUint8  = 1 shl 8 - 1;
  MaxUint16 = 1 shl 16 - 1;
  MaxUint32 = $FFFFFFFF;
  MaxUint64 = High(UInt64);

type
  // HexOrDecimal64 marshals uint64 as hex or decimal.
  HexOrDecimal64 = type UInt64;

  // THexOrDecimal64Helper provides methods for the HexOrDecimal64 type.
  THexOrDecimal64Helper = record helper for HexOrDecimal64
  public
    // UnmarshalText implements encoding.TextUnmarshaler.
    function UnmarshalText(const input: TBytes): Boolean;
    // MarshalText implements encoding.TextMarshaler.
    function MarshalText: TBytes;
  end;

// ParseUint64 parses s as an integer in decimal or hexadecimal syntax.
// Leading zeros are accepted. The empty string parses as zero.
function TryParseUInt64(const s: string; out Value: UInt64): Boolean;

// MustParseUint64 parses s as an integer and panics if the string is invalid.
function MustParseUInt64(const s: string): UInt64;

// SafeSub returns true if the subtraction resulted in an overflow.
function SafeSub(x, y: UInt64; out AResult: UInt64): Boolean;

// SafeAdd returns true if the addition resulted in an overflow.
function SafeAdd(x, y: UInt64; out AResult: UInt64): Boolean;

// SafeMul returns true if the multiplication resulted in an overflow.
function SafeMul(x, y: UInt64; out AResult: UInt64): Boolean;

implementation

uses System.StrUtils;

{ THexOrDecimal64Helper }

function THexOrDecimal64Helper.MarshalText: TBytes;
var
  s: string;
begin
  s := Format('0x%x', [UInt64(Self)]);
  Result := TEncoding.UTF8.GetBytes(s);
end;

function THexOrDecimal64Helper.UnmarshalText(const input: TBytes): Boolean;
var
  s: string;
  val: UInt64;
begin
  s := TEncoding.UTF8.GetString(input);
  Result := TryParseUInt64(s, val);
  if Result then
    Self := HexOrDecimal64(val);
end;

function TryParseUInt64(const s: string; out Value: UInt64): Boolean;
var
  Code: Integer;
  s_trimmed: string;
begin
  s_trimmed := s.Trim;
  if s_trimmed = '' then
  begin
    Value := 0;
    Result := True;
    Exit;
  end;

  if s_trimmed.StartsWith('0x', True) then
  begin
    // Delphi's Val doesn't support '0x', it uses '$' for hex.
    Val('$' + s_trimmed.Substring(2), Value, Code);
    Result := Code = 0;
  end
  else
  begin
    Result := UInt64.TryParse(s_trimmed, Value);
  end;
end;

function MustParseUInt64(const s: string): UInt64;
begin
  if not TryParseUInt64(s, Result) then
    raise EConvertError.CreateFmt('invalid unsigned 64 bit integer: "%s"', [s]);
end;

function SafeSub(x, y: UInt64; out AResult: UInt64): Boolean;
begin
  AResult := x - y;
  Result := x < y; // True if overflow occurred
end;

function SafeAdd(x, y: UInt64; out AResult: UInt64): Boolean;
begin
  AResult := x + y;
  Result := y > MaxUint64 - x; // True if overflow occurred
end;

function SafeMul(x, y: UInt64; out AResult: UInt64): Boolean;
begin
  if (x = 0) or (y = 0) then
  begin
    AResult := 0;
    Result := False; // No overflow
    Exit;
  end;

  Result := y > (MaxUint64 div x); // True if overflow occurred

  if not Result then
    AResult := x * y
  else
    AResult := 0; // Result is undefined on overflow
end;

end.