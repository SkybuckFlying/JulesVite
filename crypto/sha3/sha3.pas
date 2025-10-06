unit V.Crypto.SHA3;

interface

uses
  System.SysUtils;

type
  IState = interface
    ['{C3D4E5F6-A7B8-4C8D-9E8F-706B5C4D3E2C}']
    // This is a placeholder for the ShakeHash interface from Go's sha3 package.
  end;

function NewShake256: IState;

implementation

type
  TShake256 = class(TInterfacedObject, IState)
    // Placeholder implementation
  end;

function NewShake256: IState;
begin
  Result := TShake256.Create;
end;

end.