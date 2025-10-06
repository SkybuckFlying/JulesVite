unit V.VM.Contract;

interface

uses
  System.SysUtils,
  V.Common.Types,
  Go.Big;

type
  ICaller = interface
    ['{A1B2C3D4-E5F6-4A8B-9C8D-7E6F5A4B3C2D}']
    // Placeholder for caller interface
  end;

  TContract = class
  private
    FCode: TBytes;
    FCodeHash: THash;
    FInput: TBytes;
    FValue: IBigInt;
    FCaller: ICaller;
    FAddress: TAddress;
  public
    constructor Create(caller: ICaller; address: TAddress; value: IBigInt);
    function AsDelegate: TContract;
    function GetOp(n: UInt64): TOpCode;
    function Code: TBytes;
    function CodeHash: THash;
    function Input: TBytes;
    function Value: IBigInt;
  end;

implementation

uses V.VM.Opcodes;

{ TContract }

constructor TContract.Create(caller: ICaller; address: TAddress; value: IBigInt);
begin
  FCaller := caller;
  FAddress := address;
  FValue := value;
end;

function TContract.AsDelegate: TContract;
begin
  // This would create a new contract instance that maintains the original
  // caller and value, but can have a different code context.
  Result := TContract.Create(FCaller, FAddress, FValue);
  Result.FCode := FCode;
  Result.FInput := FInput;
end;

function TContract.GetOp(n: UInt64): TOpCode;
begin
  if n < Length(FCode) then
    Result := FCode[n]
  else
    Result := opStop;
end;

function TContract.Code: TBytes;
begin
  Result := FCode;
end;

function TContract.CodeHash: THash;
begin
  Result := FCodeHash;
end;

function TContract.Input: TBytes;
begin
  Result := FInput;
end;

function TContract.Value: IBigInt;
begin
  Result := FValue;
end;

end.