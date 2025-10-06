{
  This unit is a temporary placeholder for the Go 'hash/fnv' package.
  It provides a minimal implementation to allow the conversion of dependent units.
}
unit V.Hash.FNV;

interface

uses
  System.SysUtils;

type
  IHash64 = interface
    ['{EADF3E3B-2F29-4A8A-9A4E-6E35A57A4645}']
    procedure Write(const data: TBytes);
    function Sum(b: TBytes): TBytes;
    procedure Reset;
  end;

function New64: IHash64;

implementation

type
  TFNV64a = class(TInterfacedObject, IHash64)
  public
    procedure Write(const data: TBytes);
    function Sum(b: TBytes): TBytes;
    procedure Reset;
  end;

procedure TFNV64a.Write(const data: TBytes);
begin
  // Placeholder
end;

function TFNV64a.Sum(b: TBytes): TBytes;
var
  hashResult: TBytes;
begin
  SetLength(hashResult, 8); // 64-bit hash
  FillChar(hashResult[0], 8, 0);
  Result := b + hashResult;
end;

procedure TFNV64a.Reset;
begin
  // Placeholder
end;

function New64: IHash64;
begin
  Result := TFNV64a.Create;
end;

end.