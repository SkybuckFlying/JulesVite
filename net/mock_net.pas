unit V.Net.MockNet;

interface

uses
  System.SysUtils,
  V.Net.NetIntf;

type
  TMockNet = class(TInterfacedObject, INetIntf)
    // This is a placeholder for a mock network implementation, used for testing.
  public
    // INet methods - placeholders
    procedure Start;
    procedure Stop;
    // ... and so on for all other INet methods.
  end;

implementation

{ TMockNet }

procedure TMockNet.Start;
begin
  // Placeholder
end;

procedure TMockNet.Stop;
begin
  // Placeholder
end;

end.