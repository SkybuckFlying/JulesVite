unit V.Net.MockChain;

interface

uses
  System.SysUtils,
  V.Ledger.Chain.ChainIntf;

type
  TMockChain = class(TInterfacedObject, IChainIntf)
    // This is a placeholder for a mock chain implementation, used for testing.
    // All methods from IChain would need to be implemented here.
  public
    // IChain methods - placeholders
    procedure Init;
    procedure Start;
    procedure Stop;
    procedure Destroy;
    // ... and so on for all other IChain methods.
  end;

implementation

{ TMockChain }

procedure TMockChain.Init;
begin
  // Placeholder
end;

procedure TMockChain.Start;
begin
  // Placeholder
end;

procedure TMockChain.Stop;
begin
  // Placeholder
end;

procedure TMockChain.Destroy;
begin
  // Placeholder
end;

end.