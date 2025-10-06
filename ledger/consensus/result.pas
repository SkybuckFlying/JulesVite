unit V.Ledger.Consensus.Result;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  V.Common.Types,
  V.Ledger.Consensus.Core.Group,
  V.Ledger.Consensus.Core.Vote;

type
  TElectionResult = record
    Plans: TArray<TMemberPlan>;
    STime, ETime: TDateTime;
    Index: UInt64;
  end;
  PElectionResult = ^TElectionResult;

function GenElectionResult(Info: TGroupInfo; Index: UInt64; const Members: TArray<TAddress>): TElectionResult; overload;
function GenElectionResult(Info: TGroupInfo; Index: UInt64; const Votes: TArray<PVote>): TElectionResult; overload;

implementation

function GenElectionResult(Info: TGroupInfo; Index: UInt64; const Members: TArray<TAddress>): TElectionResult;
var
  timeTuple: TTuple<TDateTime, TDateTime>;
begin
  timeTuple := Info.TimeIndex.Index2Time(Index);
  Result.STime := timeTuple.Item1;
  Result.ETime := timeTuple.Item2;
  Result.Plans := Info.GenPlanByAddress(Index, Members);
  Result.Index := Index;
end;

function GenElectionResult(Info: TGroupInfo; Index: UInt64; const Votes: TArray<PVote>): TElectionResult;
var
  members: TArray<TAddress>;
  v: PVote;
begin
  SetLength(members, Length(Votes));
  for v in Votes do
    members := members + [v.Addr];
  Result := GenElectionResult(Info, Index, members);
end;

end.