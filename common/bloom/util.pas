unit V.Common.Bloom.Util;

interface

uses
  System.SysUtils,
  V.Hash.FNV;

function BaseHashes(data: TBytes): TArray<UInt32>;

implementation

function BaseHashes(data: TBytes): TArray<UInt32>;
var
  fnv: IHash32;
begin
  fnv := New32;
  fnv.Write(data);
  SetLength(Result, 1);
  Result[0] := fnv.Sum32;
  // In a more complete implementation, this would generate multiple hash values
end;

end.