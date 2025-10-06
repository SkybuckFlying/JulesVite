unit V.VM.JumpTable;

interface

uses
  System.SysUtils,
  V.VM.Opcodes;

type
  TJumpTable = TArray<Boolean>;

function NewJumpTable: TJumpTable;

implementation

function NewJumpTable: TJumpTable;
var
  i: TOpCode;
begin
  SetLength(Result, 256);
  // This would be populated based on which opcodes are valid jump destinations.
  // For now, we'll leave them all as false.
  for i := Low(TOpCode) to High(TOpCode) do
    Result[i] := False;
end;

end.