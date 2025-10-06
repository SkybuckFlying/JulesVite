{
  This unit is a temporary placeholder for the Go 'common/types' package.
  It provides minimal TAddress and THash types to allow the conversion of dependent units.
}
unit V.Common.Types;

interface

uses
  System.SysUtils;

const
  AddressLength = 21;
  HashLength = 32;

type
  TAddress = array[0..AddressLength - 1] of Byte;
  THash = array[0..HashLength - 1] of Byte;

function BytesToAddress(const b: TBytes): TAddress;
function BytesToHash(const b: TBytes): THash;

implementation

uses
  System.Classes;

function BytesToAddress(const b: TBytes): TAddress;
begin
  if Length(b) <> AddressLength then
    raise Exception.Create('Invalid address length');
  Move(b[0], Result, AddressLength);
end;

function BytesToHash(const b: TBytes): THash;
begin
  if Length(b) <> HashLength then
    raise Exception.Create('Invalid hash length');
  Move(b[0], Result, HashLength);
end;

end.