{
  Copyright 2016 The go-ethereum Authors
  This file is part of the go-ethereum library.

  The go-ethereum library is free software: you can redistribute it and/or modify
  it under the terms of the GNU Lesser General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  The go-ethereum library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  GNU Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public License
  along with the go-ethereum library. If not, see <http://www.gnu.org/licenses/>.

  This file is a translation of the original Go source file:
  https://github.com/ethereum/go-ethereum/blob/master/common/hexutil/hexutil.go
}
unit V.Common.HexUtil;

interface

uses
  System.SysUtils, System.Numerics, System.StrUtils;

type
  EHexUtilError = class(Exception);
  EHexEmptyString = class(EHexUtilError);
  EHexSyntax = class(EHexUtilError);
  EHexMissingPrefix = class(EHexUtilError);
  EHexOddLength = class(EHexUtilError);
  EHexEmptyNumber = class(EHexUtilError);
  EHexLeadingZero = class(EHexUtilError);
  EHexUint64Range = class(EHexUtilError);
  EHexBig256Range = class(EHexUtilError);

// Decode decodes a hex string with 0x prefix.
function Decode(const input: string): TBytes;
function TryDecode(const input: string; out Value: TBytes): Boolean;

// MustDecode decodes a hex string with 0x prefix. It panics for invalid input.
function MustDecode(const input: string): TBytes;

// Encode encodes b as a hex string with 0x prefix.
function Encode(const b: TBytes): string;

// DecodeUint64 decodes a hex string with 0x prefix as a quantity.
function DecodeUint64(const input: string): UInt64;
function TryDecodeUint64(const input: string; out Value: UInt64): Boolean;

// MustDecodeUint64 decodes a hex string with 0x prefix as a quantity. It panics for invalid input.
function MustDecodeUint64(const input: string): UInt64;

// EncodeUint64 encodes i as a hex string with 0x prefix.
function EncodeUint64(i: UInt64): string;

// DecodeBig decodes a hex string with 0x prefix as a quantity.
function DecodeBig(const input: string): TBigInteger;
function TryDecodeBig(const input: string; out Value: TBigInteger): Boolean;

// MustDecodeBig decodes a hex string with 0x prefix as a quantity. It panics for invalid input.
function MustDecodeBig(const input: string): TBigInteger;

// EncodeBig encodes bigint as a hex string with 0x prefix.
function EncodeBig(const bigint: TBigInteger): string;

implementation

uses
  System.Classes, System.ConvUtils;

function Has0xPrefix(const input: string): Boolean;
begin
  Result := input.StartsWith('0x', True);
end;

function CheckNumber(const input: string; out raw: string): EHexUtilError;
begin
  if input.IsEmpty then
    Exit(EHexEmptyString.Create('empty hex string'));
  if not Has0xPrefix(input) then
    Exit(EHexMissingPrefix.Create('hex string without 0x prefix'));
  raw := input.Substring(2);
  if raw.IsEmpty then
    Exit(EHexEmptyNumber.Create('hex string "0x"'));
  if (raw.Length > 1) and (raw[0] = '0') then
    Exit(EHexLeadingZero.Create('hex number with leading zero digits'));
  Result := nil;
end;

// Decode
function Decode(const input: string): TBytes;
begin
  if not TryDecode(input, Result) then
    raise EHexSyntax.Create('invalid hex string');
end;

function TryDecode(const input: string; out Value: TBytes): Boolean;
begin
  Result := False;
  if input.IsEmpty then
    Exit;
  if not Has0xPrefix(input) then
    Exit;
  try
    Value := HexToBytes(input.Substring(2));
    Result := True;
  except
    on E: Exception do
      Exit;
  end;
end;

function MustDecode(const input: string): TBytes;
begin
  Result := Decode(input);
end;

// Encode
function Encode(const b: TBytes): string;
begin
  Result := '0x' + BytesToHex(b);
end;

// DecodeUint64
function DecodeUint64(const input: string): UInt64;
begin
  if not TryDecodeUint64(input, Result) then
    raise EHexSyntax.Create('invalid hex uint64');
end;

function TryDecodeUint64(const input: string; out Value: UInt64): Boolean;
var
  raw: string;
  err: EHexUtilError;
begin
  err := CheckNumber(input, raw);
  if err <> nil then
    Exit(False);

  Result := UInt64.TryParse(raw, System.Globalization.NumberStyles.HexNumber, nil, Value);
end;

function MustDecodeUint64(const input: string): UInt64;
begin
  Result := DecodeUint64(input);
end;

// EncodeUint64
function EncodeUint64(i: UInt64): string;
begin
  Result := '0x' + i.ToHexString;
end;

// DecodeBig
function DecodeBig(const input: string): TBigInteger;
begin
  if not TryDecodeBig(input, Result) then
    raise EHexSyntax.Create('invalid hex big integer');
end;

function TryDecodeBig(const input: string; out Value: TBigInteger): Boolean;
var
  raw: string;
  err: EHexUtilError;
begin
  err := CheckNumber(input, raw);
  if err <> nil then
    Exit(False);
  if raw.Length > 64 then
    Exit(False);

  Result := TBigInteger.TryParse(raw, System.Globalization.NumberStyles.HexNumber, nil, Value);
  if Result and (Value.BitLength > 256) then
    Result := False;
end;

function MustDecodeBig(const input: string): TBigInteger;
begin
  Result := DecodeBig(input);
end;

// EncodeBig
function EncodeBig(const bigint: TBigInteger): string;
begin
  if bigint.IsZero then
    Result := '0x0'
  else
    Result := '0x' + bigint.ToHexString;
end;

end.