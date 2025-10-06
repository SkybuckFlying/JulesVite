unit V.VM.Config;

interface

uses
  System.SysUtils,
  V.Common.Upgrade;

type
  TConfig = record
    // This is a placeholder for the VM's configuration.
    // It would contain settings like which forks are active, etc.
    Upgrades: IUpgrade;
  end;

implementation

end.