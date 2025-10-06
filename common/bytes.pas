{
  Copyright 2014 The go-ethereum Authors
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
  https://github.com/ethereum/go-ethereum/blob/master/common/bytes.go
}
unit V.Common.Bytes;

interface

uses
  System.SysUtils;

// ToHex returns the hex representation of b, prefixed with '0x'.
function ToHex(const b: TBytes): string;

// FromHex returns the bytes represented by the hexadecimal string s.
function FromHex(const s: string): TBytes;

// CopyBytes returns an exact copy of the provided bytes.
function CopyBytes(const b: TBytes): TBytes;

// IsHexCharacter returns true if c is a valid hexadecimal character.
function IsHexCharacter(c: AnsiChar): Boolean;

// IsHex validates whether each byte is a valid hexadecimal string.
function IsHex(const str: string): Boolean;

// Bytes2Hex returns the hexadecimal encoding of d.
function Bytes2Hex(const d: TBytes): string;

// Hex2Bytes returns the bytes represented by the hexadecimal string str.
function Hex2Bytes(const str: string): TBytes;

// Hex2BytesFixed returns bytes of a specified fixed length flen.
function Hex2BytesFixed(const str: string; flen: Integer): TBytes;

// RightPadBytes zero-pads slice to the right up to length l.
function RightPadBytes(const slice: TBytes; l: Integer): TBytes;

// LeftPadBytes zero-pads slice to the left up to length l.
function LeftPadBytes(const slice: TBytes; l: Integer): TBytes;

implementation

uses
  System.ConvUtils, System.StrUtils;

function ToHex(const b: TBytes): string;
var
  hex: string;
begin
  hex := BytesToHex(b);
  if hex.IsEmpty then
    hex := '0';
  Result := '0x' + hex;
end;

function FromHex(const s: string): TBytes;
var
  cleanS: string;
begin
  cleanS := s;
  if cleanS.StartsWith('0x', True) then
    cleanS := cleanS.Substring(2);

  if (Length(cleanS) mod 2) <> 0 then
    cleanS := '0' + cleanS;

  Result := HexToBytes(cleanS);
end;

function CopyBytes(const b: TBytes): TBytes;
var
  len: Integer;
begin
  len := Length(b);
  SetLength(Result, len);
  System.Move(b[0], Result[0], len);
end;

function IsHexCharacter(c: AnsiChar): Boolean;
begin
  Result := (c in ['0'..'9', 'a'..'f', 'A'..'F']);
end;

function IsHex(const str: string): Boolean;
var
  c: AnsiChar;
begin
  if (Length(str) mod 2) <> 0 then
    Exit(False);

  for c in str do
    if not IsHexCharacter(c) then
      Exit(False);

  Result := True;
end;

function Bytes2Hex(const d: TBytes): string;
begin
  Result := BytesToHex(d);
end;

function Hex2Bytes(const str: string): TBytes;
begin
  Result := System.ConvUtils.HexToBytes(str);
end;

function Hex2BytesFixed(const str: string; flen: Integer): TBytes;
var
  h: TBytes;
  hLen: Integer;
begin
  h := HexToBytes(str);
  hLen := Length(h);
  if hLen = flen then
    Result := h
  else if hLen > flen then
  begin
    SetLength(Result, flen);
    System.Move(h[hLen - flen], Result[0], flen);
  end
  else
  begin
    SetLength(Result, flen);
    System.Move(h[0], Result[flen - hLen], hLen);
  end;
end;

function RightPadBytes(const slice: TBytes; l: Integer): TBytes;
var
  sliceLen: Integer;
begin
  sliceLen := Length(slice);
  if l <= sliceLen then
    Exit(slice);

  SetLength(Result, l);
  System.Move(slice[0], Result[0], sliceLen);
end;

function LeftPadBytes(const slice: TBytes; l: Integer): TBytes;
var
  sliceLen: Integer;
begin
  sliceLen := Length(slice);
  if l <= sliceLen then
    Exit(slice);

  SetLength(Result, l);
  System.Move(slice[0], Result[l - sliceLen], sliceLen);
end;

end.