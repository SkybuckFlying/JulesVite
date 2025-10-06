{
  This unit is a temporary placeholder for the Go 'vm/abi' package.
  It provides minimal definitions to allow the conversion of dependent units.
}
unit V.VM.ABI;

interface

uses
  System.SysUtils, System.Classes,
  V.Common.Types;

type
  TArgument = record
    Name: string;
    Type_: string; // 'Type' is a keyword in Delphi
    Indexed: Boolean;
  end;

  TMethod = record
    Name: string;
    Inputs: TArray<TArgument>;
    Outputs: TArray<TArgument>;
    function Id: TBytes;
  end;

  TEvent = record
    Name: string;
    Inputs: TArray<TArgument>;
    IndexedInputs: TArray<TArgument>;
    NonIndexedInputs: TArray<TArgument>;
    function Id: THash;
  end;

  TVariable = record
    Name: string;
    Inputs: TArray<TArgument>;
  end;

  TAbiContract = class
  public
    Constructor: TMethod;
    Methods: TDictionary<string, TMethod>;
    Callbacks: TDictionary<string, TMethod>;
    OffChains: TDictionary<string, TMethod>;
    Events: TDictionary<string, TEvent>;
    Variables: TDictionary<string, TVariable>;
    constructor Create;
    destructor Destroy; override;
    function MethodById(const Selector: TBytes): TMethod;
    function PackMethod(const Name: string; const Args: array of const): TBytes;
    function PackEvent(const Name: string; const Args: array of const): TArray<THash>;
    procedure UnpackMethod(var V: TObject; const Name: string; const Input: TBytes);
  end;

implementation

uses System.Generics.Collections;

{ TMethod }
function TMethod.Id: TBytes;
begin
  // Placeholder
  SetLength(Result, 4);
end;

{ TEvent }
function TEvent.Id: THash;
begin
  // Placeholder
end;

{ TAbiContract }
constructor TAbiContract.Create;
begin
  inherited;
  Methods := TDictionary<string, TMethod>.Create;
  Callbacks := TDictionary<string, TMethod>.Create;
  OffChains := TDictionary<string, TMethod>.Create;
  Events := TDictionary<string, TEvent>.Create;
  Variables := TDictionary<string, TVariable>.Create;
end;

destructor TAbiContract.Destroy;
begin
  Methods.Free;
  Callbacks.Free;
  OffChains.Free;
  Events.Free;
  Variables.Free;
  inherited;
end;

function TAbiContract.MethodById(const Selector: TBytes): TMethod;
begin
  // Placeholder
end;

function TAbiContract.PackMethod(const Name: string; const Args: array of const): TBytes;
begin
  Result := nil; // Placeholder
end;

function TAbiContract.PackEvent(const Name: string; const Args: array of const): TArray<THash>;
begin
  Result := nil; // Placeholder
end;

procedure TAbiContract.UnpackMethod(var V: TObject; const Name: string; const Input: TBytes);
begin
  // Placeholder
end;

end.