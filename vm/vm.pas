unit V.VM;

interface

uses
  System.SysUtils,
  V.Common.Types,
  V.VM.Config,
  V.VM.Interpreter,
  V.VM.Database,
  V.VM.Quota;

type
  IVM = interface
    ['{A1B2C3D4-E5F6-4A8B-9C8D-7E6F5A4B3C2E}']
    function Call(caller: ICaller; toAddr: TAddress; input: TBytes; gas: UInt64; value: IBigInt): TTuple<TBytes, UInt64, Error>;
    function Create(caller: ICaller; code: TBytes; gas: UInt64; value: IBigInt): TTuple<TBytes, TAddress, UInt64, Error>;
  end;

  TVM = class(TInterfacedObject, IVM)
  private
    FCfg: TConfig;
    FDb: IDatabase;
  public
    constructor Create(cfg: TConfig; db: IDatabase);
    function Call(caller: ICaller; toAddr: TAddress; input: TBytes; gas: UInt64; value: IBigInt): TTuple<TBytes, UInt64, Error>;
    function Create(caller: ICaller; code: TBytes; gas: UInt64; value: IBigInt): TTuple<TBytes, TAddress, UInt64, Error>;
  end;

function NewVM(cfg: TConfig; db: IDatabase): IVM;

implementation

uses
  Go.Big;

{ TVM }

constructor TVM.Create(cfg: TConfig; db: IDatabase);
begin
  FCfg := cfg;
  FDb := db;
end;

function TVM.Call(caller: ICaller; toAddr: TAddress; input: TBytes; gas: UInt64; value: IBigInt): TTuple<TBytes, UInt64, Error>;
var
  interpreter: IInterpreter;
  contract: TContract;
begin
  interpreter := NewInterpreter(FDb, FCfg);
  contract := TContract.Create(caller, toAddr, value);
  // In a real implementation, you would load the contract code here.
  // contract.FCode := FDb.GetCode(toAddr);
  Result := interpreter.Run(contract, input);
end;

function TVM.Create(caller: ICaller; code: TBytes; gas: UInt64; value: IBigInt): TTuple<TBytes, TAddress, UInt64, Error>;
var
  interpreter: IInterpreter;
  contract: TContract;
  newAddr: TAddress; // Address would be derived from caller and nonce
begin
  interpreter := NewInterpreter(FDb, FCfg);
  contract := TContract.Create(caller, newAddr, value);
  contract.FCode := code;
  // The Run method would need to handle contract creation logic.
  // This is a simplified representation.
  var runResult := interpreter.Run(contract, nil);
  Result := TTuple.Create(runResult.Item1, newAddr, gas - 0, runResult.Item2); // Placeholder for gas used
end;

function NewVM(cfg: TConfig; db: IDatabase): IVM;
begin
  Result := TVM.Create(cfg, db);
end;

end.