unit V.VM.Memory;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  TMemory = class
  private
    FStore: TBytes;
  public
    procedure Set(offset, size: UInt64; value: TBytes);
    function Get(offset, size: UInt64): TBytes;
    function Len: Integer;
  end;

implementation

{ TMemory }

procedure TMemory.Set(offset, size: UInt64; value: TBytes);
var
  requiredSize: UInt64;
begin
  requiredSize := offset + size;
  if requiredSize > Length(FStore) then
    SetLength(FStore, requiredSize);

  System.Move(value[0], FStore[offset], size);
end;

function TMemory.Get(offset, size: UInt64): TBytes;
var
  requiredSize: UInt64;
begin
  requiredSize := offset + size;
  if requiredSize > Length(FStore) then
    raise EAccessViolation.Create('invalid memory access');

  SetLength(Result, size);
  System.Move(FStore[offset], Result[0], size);
end;

function TMemory.Len: Integer;
begin
  Result := Length(FStore);
end;

end.