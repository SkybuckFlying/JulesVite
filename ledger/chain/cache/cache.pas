{
  This unit is a temporary placeholder for the Go 'ledger/chain/cache' package.
  It provides a minimal TCache class to allow the conversion of dependent units.
}
unit V.Ledger.Chain.Cache;

interface

uses
  System.SysUtils, V.Ledger.Chain.Interface;

type
  // TCache is a placeholder for the chain cache.
  TCache = class
  public
    constructor Create(AChain: IChain);
    procedure Init;
    procedure Destroy;
  end;

implementation

{ TCache }

constructor TCache.Create(AChain: IChain);
begin
  // Placeholder
end;

procedure TCache.Init;
begin
  // Placeholder
end;

procedure TCache.Destroy;
begin
  // Placeholder
end;

end.