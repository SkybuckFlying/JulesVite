unit V.Ledger.Consensus.Api;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  V.Common.Types,
  V.Interfaces.Core,
  V.Ledger.Consensus.Cdb,
  V.Ledger.Consensus.Snapshot,
  V.Ledger.Consensus.Event,
  V.Ledger.Consensus.Result;

type
  TAPISnapshot = record
  private
    FSnapshot: ISnapshotCs;
  public
    function ReadVoteMap(ti: TDateTime): TTuple<TArray<TVoteDetails>, PHashHeight, Error>;
    function ReadSuccessRate(start, &end: UInt64): TTuple<TArray<TDictionary<TAddress, TContent>>, Error>;
    function ReadByIndex(gid: TGid; index: UInt64): TTuple<TArray<PConsensusEvent>, UInt64, Error>;
  end;

implementation

{ TAPISnapshot }

function TAPISnapshot.ReadByIndex(gid: TGid; index: UInt64): TTuple<TArray<PConsensusEvent>, UInt64, Error>;
var
  eResult: TElectionResult;
  err: Error;
  voteTime: TDateTime;
  result: TArray<PConsensusEvent>;
  p: TMemberPlan;
  e: TConsensusEvent;
begin
  Tuple.Create(eResult, err) := FSnapshot.ElectionIndex(index);
  if err <> nil then
  begin
    Result := TTuple.Create(nil, 0, err);
    Exit;
  end;

  voteTime := FSnapshot.GenProofTime(index);
  SetLength(result, 0);
  for p in eResult.Plans do
  begin
    e := NewConsensusEvent(eResult, p, gid, voteTime);
    result := result + [@e];
  end;
  Result := TTuple.Create(result, eResult.Index, nil);
end;

function TAPISnapshot.ReadSuccessRate(start, &end: UInt64): TTuple<TArray<TDictionary<TAddress, TContent>>, Error>;
var
  result: TArray<TDictionary<TAddress, TContent>>;
  i: UInt64;
  rateByHour: TDictionary<TAddress, TContent>;
  err: Error;
begin
  SetLength(result, 0);
  for i := start to &end - 1 do
  begin
    // This method is on chainRw, not snapshot. This will need to be fixed later.
    // Tuple.Create(rateByHour, err) := FSnapshot.rw.GetSuccessRateByHour2(i);
    // if err <> nil then
    //   raise EProgrammerException.Create('Error reading success rate');
    // result := result + [rateByHour];
  end;
  Result := TTuple.Create(result, nil);
end;

function TAPISnapshot.ReadVoteMap(ti: TDateTime): TTuple<TArray<TVoteDetails>, PHashHeight, Error>;
begin
  Result := FSnapshot.VoteDetailsBeforeTime(ti);
end;

end.