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
  V.Ledger.Consensus.Result,
  V.Ledger.Consensus; // For IAPIConsensusReader

type
  TAPISnapshot = class(TInterfacedObject, IAPIConsensusReader)
  private
    FSnapshot: ISnapshotCs;
  public
    constructor Create(snapshot: ISnapshotCs);
    function ReadVoteMap(ti: TDateTime): TTuple<TArray<TVoteDetails>, PHashHeight, Error>;
    function ReadSuccessRate(start, &end: UInt64): TTuple<TArray<TDictionary<TAddress, TContent>>, Error>;
    function ReadByIndex(gid: TGid; index: UInt64): TTuple<TArray<PConsensusEvent>, UInt64, Error>;
  end;

function NewAPISnapshot(snapshot: ISnapshotCs): IAPIConsensusReader;

implementation

{ TAPISnapshot }

constructor TAPISnapshot.Create(snapshot: ISnapshotCs);
begin
  FSnapshot := snapshot;
end;

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
begin
  // This logic was incorrect as it tried to access a private field of another class.
  // The correct implementation would involve passing the IChainRw interface or
  // having the Snapshot object expose this functionality.
  // For now, returning an empty result.
  Result := TTuple.Create(nil, EProgrammerException.Create('ReadSuccessRate not fully implemented'));
end;

function TAPISnapshot.ReadVoteMap(ti: TDateTime): TTuple<TArray<TVoteDetails>, PHashHeight, Error>;
begin
  Result := FSnapshot.VoteDetailsBeforeTime(ti);
end;

function NewAPISnapshot(snapshot: ISnapshotCs): IAPIConsensusReader;
begin
  Result := TAPISnapshot.Create(snapshot);
end;

end.