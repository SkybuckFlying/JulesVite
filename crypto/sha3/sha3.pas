{
  This unit is a temporary placeholder for the Go 'sha3' package.
  It provides a minimal implementation to allow the conversion of dependent units.
}
unit V.Crypto.SHA3;

interface

uses
  System.SysUtils, V.Crypto.Blake2b; // Reusing IHash from Blake2b for simplicity

// NewLegacyKeccak256 returns a new Keccak-256 hash.
function NewLegacyKeccak256: IHash;

implementation

type
  TKeccak256 = class(TInterfacedObject, IHash)
  public
    procedure Write(const data: TBytes);
    function Sum(const b: TBytes): TBytes;
    procedure Reset;
  end;

procedure TKeccak256.Write(const data: TBytes);
begin
  // Placeholder implementation
end;

function TKeccak256.Sum(const b: TBytes): TBytes;
var
  hashResult: TBytes;
begin
  SetLength(hashResult, 32); // Keccak-256 produces a 32-byte hash
  FillChar(hashResult[0], 32, 0);
  Result := b + hashResult;
end;

procedure TKeccak256.Reset;
begin
  // Placeholder implementation
end;

function NewLegacyKeccak256: IHash;
begin
  Result := TKeccak256.Create;
end;

end.