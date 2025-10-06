{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/crypto/hash.go
}
unit V.Crypto.Hash;

interface

uses
  System.SysUtils;

// Hash256 computes the Blake2b-256 hash of the data.
function Hash256(const Data: array of TBytes): TBytes;

// Keccak256 computes the Keccak-256 hash of the data.
function Keccak256(const Data: array of TBytes): TBytes;

// Hash512 computes the Blake2b-512 hash of the data.
function Hash512(const Data: array of TBytes): TBytes;

// Hash computes the Blake2b hash of the data with a given size.
function Hash(Size: Integer; const Data: array of TBytes): TBytes;

implementation

uses
  V.Crypto.Blake2b, V.Crypto.SHA3;

function Hash256(const Data: array of TBytes): TBytes;
var
  d: IHash;
  item: TBytes;
begin
  d := V.Crypto.Blake2b.New256(nil);
  for item in Data do
  begin
    d.Write(item);
  end;
  Result := d.Sum(nil);
end;

function Keccak256(const Data: array of TBytes): TBytes;
var
  d: IHash;
  item: TBytes;
begin
  d := V.Crypto.SHA3.NewLegacyKeccak256;
  for item in Data do
  begin
    d.Write(item);
  end;
  Result := d.Sum(nil);
end;

function Hash512(const Data: array of TBytes): TBytes;
var
  d: IHash;
  item: TBytes;
begin
  d := V.Crypto.Blake2b.New512(nil);
  for item in Data do
  begin
    d.Write(item);
  end;
  Result := d.Sum(nil);
end;

function Hash(Size: Integer; const Data: array of TBytes): TBytes;
var
  d: IHash;
  item: TBytes;
begin
  d := V.Crypto.Blake2b.New(Size, nil);
  for item in Data do
  begin
    d.Write(item);
  end;
  Result := d.Sum(nil);
end;

end.