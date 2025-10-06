unit V.Crypto.Hash;

interface

uses
  System.SysUtils,
  V.Common.Types;

function Keccak256(data: array of TBytes): THash;

implementation

uses
  System.Hash;

function Keccak256(data: array of TBytes): THash;
var
  hasher: IHasher;
  i: Integer;
begin
  hasher := THashSHA3.Create(THashSHA3.TSHAKE.sha3_256);
  for i := Low(data) to High(data) do
    hasher.Update(data[i]);
  Result := THash.FromBytes(hasher.GetHashBytes);
end;

end.