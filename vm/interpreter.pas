unit V.VM.Interpreter;

interface

uses
  System.SysUtils,
  V.Common.Types,
  V.VM.Config,
  V.VM.Database,
  V.VM.Stack,
  V.VM.Memory,
  V.VM.Contract,
  V.VM.JumpTable;

type
  IInterpreter = interface
    ['{C3D4E5F6-A7B8-4C8D-9E8F-706B5C4D3E2F}']
    function Run(contract: TContract; input: TBytes): TTuple<TBytes, Error>;
  end;

  TInterpreter = class(TInterfacedObject, IInterpreter)
  private
    FDb: IDatabase;
    FCfg: TConfig;
    FJumpTable: TJumpTable;
    FReadOnly: Boolean;
    FGas: UInt64;
  public
    constructor Create(db: IDatabase; cfg: TConfig);
    function Run(contract: TContract; input: TBytes): TTuple<TBytes, Error>;
  end;

function NewInterpreter(db: IDatabase; cfg: TConfig): IInterpreter;

implementation

{ TInterpreter }

constructor TInterpreter.Create(db: IDatabase; cfg: TConfig);
begin
  FDb := db;
  FCfg := cfg;
  FJumpTable := NewJumpTable;
end;

function TInterpreter.Run(contract: TContract; input: TBytes): TTuple<TBytes, Error>;
var
  stack: TStack;
  mem: TMemory;
  op: TOpCode;
  pc: UInt64;
  ret: TBytes;
  err: Error;
begin
  stack := TStack.Create;
  mem := TMemory.Create;
  pc := 0;
  ret := nil;
  err := nil;

  try
    while True do
    begin
      op := contract.GetOp(pc);

      // In a real implementation, a large case statement or dispatch table
      // would handle each opcode.
      // op.Execute(stack, mem, contract, self);

      case op of
        // opStop, opReturn, etc. would break the loop
      else
        Inc(pc);
      end;

      if op = $00 // opStop
      then Break;
    end;
  finally
    stack.Free;
    mem.Free;
  end;

  Result := TTuple.Create(ret, err);
end;

function NewInterpreter(db: IDatabase; cfg: TConfig): IInterpreter;
begin
  Result := TInterpreter.Create(db, cfg);
end;

end.