{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/vm/interpreter.go
}
unit V.VM.Interpreter;

interface

uses
  System.SysUtils,
  V.VM.Contract, V.VM.Opcodes;

type
  TVM = class; // Forward declaration

  TInterpreter = class
  private
    FInstructionSet: array[TOpCode] of TOperation; // From V.VM.JumpTable
  public
    constructor Create(BlockHeight: UInt64; OffChain: Boolean);
    function RunLoop(var VM: TVM; var C: TContract): TBytes;
  end;

implementation

uses
  System.Classes, System.Threading,
  V.Common.Upgrade, V.VM.Config, V.VM.Memory, V.VM.Stack, V.VM.JumpTable,
  V.Common.Helper, V.VM.Util;

{ TInterpreter }

constructor TInterpreter.Create(BlockHeight: UInt64; OffChain: Boolean);
begin
  inherited Create;
  if IsEarthUpgrade(BlockHeight) then
  begin
    if OffChain then
      FInstructionSet := OffchainEarthInstructionSet
    else
      FInstructionSet := EarthInstructionSet;
  end
  else if IsSeedUpgrade(BlockHeight) then
  begin
    if OffChain then
      FInstructionSet := OffchainRandInstructionSet
    else
      FInstructionSet := RandInstructionSet;
  end
  else
  begin
    if OffChain then
      FInstructionSet := OffchainSimpleInstructionSet
    else
      FInstructionSet := SimpleInstructionSet;
  end;
end;

function TInterpreter.RunLoop(var VM: TVM; var C: TContract): TBytes;
var
  op: TOpCode;
  mem: TMemory;
  st: TStack;
  pc: UInt64;
  cost: UInt64;
  flag: Boolean;
  err: Exception;
  operation: TOperation;
  memorySize: UInt64;
  memSizeBig: TBigInteger;
  overflow: Boolean;
  res: TBytes;
begin
  // C.ReturnData := nil; // Assuming TContract has ReturnData field
  mem := TMemory.Create;
  st := TStack.Create;
  pc := 0;
  try
    while True do // Simplified from atomic check
    begin
      op := TOpCode(C.GetOp(pc)); // Assuming TContract has GetOp method
      operation := FInstructionSet[op];

      if not operation.Valid then
        raise EInvalidOpCode.Create('Invalid opcode');

      operation.ValidateStack(st);

      memorySize := 0;
      if Assigned(operation.MemorySize) then
      begin
        memSizeBig := operation.MemorySize(st);
        // Simplified overflow check
        memorySize := memSizeBig.ToUInt64;
      end;

      cost := operation.GasCost(VM, C, st, mem, memorySize);
      // C.QuotaLeft := UseQuotaWithFlag(C.QuotaLeft, cost, flag); // Placeholder

      if memorySize > 0 then
        mem.Resize(memorySize);

      res := operation.Execute(pc, VM, C, mem, st);

      if NodeConfig.IsDebug then
      begin
        // Logging logic here
      end;

      if operation.Returns then
      begin
        // C.ReturnData := res;
      end;

      if operation.Halts then
        Exit(res);
      if operation.Reverts then
        raise EExecutionReverted.Create('Execution reverted');
      if not operation.Jumps then
        Inc(pc);
    end;
  except
    on E: Exception do
    begin
      Result := nil;
      // Handle exception, possibly re-raise
    end;
  end;
end;

end.