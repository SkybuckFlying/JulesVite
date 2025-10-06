unit V.Ledger.Pool.Lock;

interface

uses
  System.SysUtils;

type
  IChainRollback = interface
    ['{A1B2C3D4-E5F6-4A8B-9C8D-7E6F5A4B3C2F}']
    procedure Lock;
    procedure Unlock;
  end;

implementation

end.