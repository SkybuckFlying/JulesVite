{
  This unit is a temporary placeholder for the Go 'vm/contracts' package.
  It provides minimal definitions to allow the conversion of dependent units.
}
unit V.VM.Contracts;

interface

uses
  System.SysUtils, System.Numerics,
  V.Common.Types, V.Interfaces, V.Interfaces.Core, V.VM.Util;

type
  IBuiltinContractMethod = interface
    ['{A1B2C3D4-E5F6-4A8B-9C8D-7E6F5A4B3C2D}']
    function GetSendQuota(const Data: TBytes; GasTable: TQuotaTable): UInt64;
    // Other methods would be defined here
  end;

function GetBuiltinContractMethod(const Addr: TAddress; const MethodSelector: TBytes; SbHeight: UInt64): IBuiltinContractMethod;

implementation

function GetBuiltinContractMethod(const Addr: TAddress; const MethodSelector: TBytes; SbHeight: UInt64): IBuiltinContractMethod;
begin
  Result := nil; // Placeholder
end;

end.