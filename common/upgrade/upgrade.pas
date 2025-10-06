{
  This unit is a temporary placeholder for the Go 'common/upgrade' package.
  It provides a minimal implementation to allow the conversion of dependent units.
}
unit V.Common.Upgrade;

interface

uses
  System.SysUtils;

type
  TUpgradePoint = record
    Name: string;
    Height: UInt64;
    Version: UInt32;
  end;

  IUpgradeBox = interface
    ['{A1B2C3D4-E5F6-4A8B-9C8D-7E6F5A4B3C2D}']
    function IsActive(Version: UInt32; Height: UInt64): Boolean;
    // Other methods would be defined here
  end;

var
  Upgrade: IUpgradeBox;

function IsSeedUpgrade(SHeight: UInt64): Boolean;
function IsEarthUpgrade(SHeight: UInt64): Boolean;

implementation

type
  TUpgradeBox = class(TInterfacedObject, IUpgradeBox)
  public
    function IsActive(Version: UInt32; Height: UInt64): Boolean;
  end;

function TUpgradeBox.IsActive(Version: UInt32; Height: UInt64): Boolean;
begin
  // Placeholder: always return true to allow new features to be used.
  Result := True;
end;

function IsSeedUpgrade(SHeight: UInt64): Boolean;
begin
  if not Assigned(Upgrade) then
    raise Exception.Create('Upgrade box not initialized');
  Result := Upgrade.IsActive(1, SHeight);
end;

function IsEarthUpgrade(SHeight: UInt64): Boolean;
begin
  if not Assigned(Upgrade) then
    raise Exception.Create('Upgrade box not initialized');
  Result := Upgrade.IsActive(6, SHeight);
end;

initialization
  Upgrade := TUpgradeBox.Create;
end.