{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/vm/gas_table.go
}
unit V.VM.GasTable;

interface

uses
  System.SysUtils, System.Numerics,
  V.VM.Memory, V.VM.Stack, V.VM.Contract, V.Interfaces.Core, V.VM.Util;

type
  TVM = class; // Forward declaration

function GasAdd(var VM: TVM; var C: TContract; Stack: TStack; Mem: TMemory; MemorySize: UInt64): UInt64;
function GasMul(var VM: TVM; var C: TContract; Stack: TStack; Mem: TMemory; MemorySize: UInt64): UInt64;
// ... other gas function declarations ...

function GasRequiredForBlock(DB: TObject; Block: PAccountBlock; GasTable: TQuotaTable; SbHeight: UInt64): UInt64;

implementation

uses V.Common.Helper, V.Common.Upgrade, V.VM.Contracts;

function MemoryGasCost(var VM: TVM; Mem: TMemory; NewMemSize: UInt64): UInt64;
var
  newMemSizeWords, square, linCoef, quadCoef, newTotalFee, fee: UInt64;
begin
  if NewMemSize = 0 then Exit(0);
  // Simplified overflow check
  if NewMemSize > $FFFFFFFFE0 then
    raise EOverflow.Create('Gas uint overflow');

  newMemSizeWords := ToWordSize(NewMemSize);
  NewMemSize := newMemSizeWords * 32; // WordSize

  if NewMemSize > Mem.Size then
  begin
    square := newMemSizeWords * newMemSizeWords;
    // linCoef := newMemSizeWords * VM.GasTable.MemQuota;
    // quadCoef := square div VM.GasTable.MemQuotaDivision;
    newTotalFee := linCoef + quadCoef;
    // fee := newTotalFee - Mem.LastGasCost;
    // Mem.LastGasCost := newTotalFee;
    Result := fee;
  end
  else
    Result := 0;
end;

function GasAdd(var VM: TVM; var C: TContract; Stack: TStack; Mem: TMemory; MemorySize: UInt64): UInt64;
begin
  // Result := VM.GasTable.AddQuota;
end;

function GasMul(var VM: TVM; var C: TContract; Stack: TStack; Mem: TMemory; MemorySize: UInt64): UInt64;
begin
  // Result := VM.GasTable.MulQuota;
end;

// ... other gas function implementations ...

function GasRequiredForBlock(DB: TObject; Block: PAccountBlock; GasTable: TQuotaTable; SbHeight: UInt64): UInt64;
var
  cost: UInt64;
  method: IBuiltinContractMethod;
  ok: Boolean;
  quotaMultiplier: Byte;
begin
  if Block.BlockType = BlockTypeReceive then
  begin
    // Result := GasReceive(Block, nil, GasTable);
    Exit;
  end;

  // cost := GasRequiredForSendBlock(Block, GasTable, SbHeight);
  if Block.BlockType <> BlockTypeSendCall then
  begin
    Result := cost;
    Exit;
  end;

  // method, ok, _ := GetBuiltinContractMethod(Block.ToAddress, Block.Data, SbHeight);
  if ok then
  begin
    // cost := method.GetSendQuota(Block.Data, GasTable);
  end;

  // quotaMultiplier := GetQuotaMultiplierForS(DB, Block.ToAddress);
  // Result := MultipleCost(cost, quotaMultiplier);
end;

end.