{
  This unit is a temporary placeholder for the Go 'ledger/consensus/core' package.
  It provides minimal definitions to allow the conversion of dependent units.
}
unit V.Ledger.Consensus.Core;

interface

uses
  System.SysUtils, V.Common.Types;

type
  // ISBPStatReader provides read-only access to SBP statistics.
  ISBPStatReader = interface
    ['{A1B2C3D4-E5F6-4A8B-9C8D-7E6F5A4B3C2D}']
    // Placeholder methods
  end;

  // TMemberPlan defines the block production plan for a single member.
  TMemberPlan = record
    Member: TAddress;
    STime, ETime: TDateTime;
  end;
  PMemberPlan = ^TMemberPlan;
  TMemberPlanArray = array of PMemberPlan;

  // TGroupInfo is a placeholder for consensus group information.
  TGroupInfo = record
    function Index2Time(Index: UInt64; out STime, ETime: TDateTime): Boolean;
    function GenPlanByAddress(Index: UInt64; const Members: TArray<TAddress>): TMemberPlanArray;
  end;
  PGroupInfo = ^TGroupInfo;

implementation

{ TGroupInfo }

function TGroupInfo.Index2Time(Index: UInt64; out STime, ETime: TDateTime): Boolean;
begin
  // Placeholder
  STime := Now;
  ETime := Now;
  Result := True;
end;

function TGroupInfo.GenPlanByAddress(Index: UInt64; const Members: TArray<TAddress>): TMemberPlanArray;
begin
  Result := nil; // Placeholder
end;

end.