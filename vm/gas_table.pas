unit V.VM.GasTable;

interface

uses
  System.SysUtils,
  V.VM.Params;

type
  TGasTable = TArray<UInt64>;

function NewGasTable: TGasTable;

implementation

function NewGasTable: TGasTable;
begin
  SetLength(Result, 256);
  // This would be populated with the gas costs for each opcode.
  // For now, we'll initialize with zeros.
end;

end.