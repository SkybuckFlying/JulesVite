{
  This unit is a temporary placeholder for the Go 'wallet' package.
  It provides a minimal TWalletManager class to allow the conversion of dependent units.
}
unit V.Wallet;

interface

uses
  System.SysUtils, V.Common.Config;

type
  TWalletManager = class
  public
    constructor Create(AConfig: TWalletConfig);
    procedure Start;
    procedure Stop;
    procedure AddEntropyStore(const Path: string);
    procedure Unlock(const Path, Password string);
  end;

implementation

{ TWalletManager }

constructor TWalletManager.Create(AConfig: TWalletConfig);
begin
  // Placeholder
end;

procedure TWalletManager.Start;
begin
  // Placeholder
end;

procedure TWalletManager.Stop;
begin
  // Placeholder
end;

procedure TWalletManager.AddEntropyStore(const Path: string);
begin
  // Placeholder
end;

procedure TWalletManager.Unlock(const Path, Password string);
begin
  // Placeholder
end;

end.