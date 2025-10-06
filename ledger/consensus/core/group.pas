unit V.Ledger.Consensus.Core.Group;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Go.Big,
  V.Common.Types,
  V.Ledger.Consensus.Core.TimeIndexer,
  V.Ledger.Consensus.Core.Vote;

type
  TMemberPlan = record
    STime: TDateTime;
    ETime: TDateTime;
    Member: TAddress;
    Name: string;
  end;

  TGroupInfo = class
  private
    FTimeIndex: ITimeIndex;
    FConsensusGroupInfo: TConsensusGroupInfo;
    FGenesisTime: TDateTime;
    FSeed: IBigInt;
    FPlanInterval: UInt64;
    function GetTimeIndex: ITimeIndex;
    function GetConsensusGroupInfo: TConsensusGroupInfo;
    function GetGenesisTime: TDateTime;
    function GetSeed: IBigInt;
    function GetPlanInterval: UInt64;
  public
    constructor Create(genesisTime: TDateTime; info: TConsensusGroupInfo);
    function GenPlan(index: UInt64; members: TArray<PVote>): TArray<TMemberPlan>;
    function GenPlanByAddress(index: UInt64; members: TArray<TAddress>): TArray<TMemberPlan>;
    function ToString: string;
    property TimeIndex: ITimeIndex read GetTimeIndex;
    property ConsensusGroupInfo: TConsensusGroupInfo read GetConsensusGroupInfo;
    property GenesisTime: TDateTime read GetGenesisTime;
    property Seed: IBigInt read GetSeed;
    property PlanInterval: UInt64 read GetPlanInterval;
  end;

function NewGroupInfo(genesisTime: TDateTime; info: TConsensusGroupInfo): TGroupInfo;
function PlanInterval(info: TGroupInfo): UInt64;

implementation

uses
  System.DateUtils;

{ TGroupInfo }

constructor TGroupInfo.Create(genesisTime: TDateTime; info: TConsensusGroupInfo);
begin
  FConsensusGroupInfo := info;
  FGenesisTime := genesisTime;
  FSeed := TBigInt.New.SetBytes(info.Gid.Bytes);
  FPlanInterval := PlanInterval(Self);
  FTimeIndex := NewTimeIndex(genesisTime, TTimeSpan.FromSeconds(FPlanInterval));
end;

function TGroupInfo.GenPlan(index: UInt64; members: TArray<PVote>): TArray<TMemberPlan>;
var
  sTime: TDateTime;
  plans: TArray<TMemberPlan>;
  member: PVote;
  i: Int64;
  etime: TDateTime;
  plan: TMemberPlan;
begin
  sTime := TimeIndex.Index2Time(index).Item1;
  SetLength(plans, 0);
  for member in members do
  begin
    for i := 0 to ConsensusGroupInfo.PerCount - 1 do
    begin
      etime := sTime + TTimeSpan.FromSeconds(ConsensusGroupInfo.Interval);
      plan.STime := sTime;
      plan.ETime := etime;
      plan.Member := member.Addr;
      plan.Name := member.Name;
      plans := plans + [plan];
      sTime := etime;
    end;
  end;
  Result := plans;
end;

function TGroupInfo.GenPlanByAddress(index: UInt64; members: TArray<TAddress>): TArray<TMemberPlan>;
var
  sTime: TDateTime;
  plans: TArray<TMemberPlan>;
  j: UInt16;
  member: TAddress;
  i: Int64;
  etime: TDateTime;
  plan: TMemberPlan;
begin
  sTime := TimeIndex.Index2Time(index).Item1;
  SetLength(plans, 0);

  if Length(members) > ConsensusGroupInfo.NodeCount then
  begin
    // errors
    Result := nil;
    Exit;
  end;

  for j := 0 to ConsensusGroupInfo.Repeat - 1 do
  begin
    for member in members do
    begin
      for i := 0 to ConsensusGroupInfo.PerCount - 1 do
      begin
        etime := sTime + TTimeSpan.FromSeconds(ConsensusGroupInfo.Interval);
        plan.STime := sTime;
        plan.ETime := etime;
        plan.Member := member;
        plans := plans + [plan];
        sTime := etime;
      end;
    end;
    if Length(members) < ConsensusGroupInfo.NodeCount then
      sTime := sTime + TTimeSpan.FromSeconds(ConsensusGroupInfo.Interval * ConsensusGroupInfo.PerCount * (ConsensusGroupInfo.NodeCount - Length(members)));
  end;
  Result := plans;
end;

function TGroupInfo.GetConsensusGroupInfo: TConsensusGroupInfo;
begin
  Result := FConsensusGroupInfo;
end;

function TGroupInfo.GetGenesisTime: TDateTime;
begin
  Result := FGenesisTime;
end;

function TGroupInfo.GetPlanInterval: UInt64;
begin
  Result := FPlanInterval;
end;

function TGroupInfo.GetSeed: IBigInt;
begin
  Result := FSeed;
end;

function TGroupInfo.GetTimeIndex: ITimeIndex;
begin
  Result := FTimeIndex;
end;

function TGroupInfo.ToString: string;
begin
  Result := Format('genesisTime:%s, memberCnt:%d, interval:%d, perCnt:%d, randCnt:%d, randRange:%d, seed:%s, countingTokenId:%s',
    [DateTimeToStr(GenesisTime), ConsensusGroupInfo.NodeCount, ConsensusGroupInfo.Interval, ConsensusGroupInfo.PerCount,
    ConsensusGroupInfo.RandCount, ConsensusGroupInfo.RandRank, Seed.ToString, ConsensusGroupInfo.CountingTokenId.ToString]);
end;

function NewGroupInfo(genesisTime: TDateTime; info: TConsensusGroupInfo): TGroupInfo;
begin
  Result := TGroupInfo.Create(genesisTime, info);
end;

function PlanInterval(info: TGroupInfo): UInt64;
begin
  Result := info.ConsensusGroupInfo.Interval * info.ConsensusGroupInfo.NodeCount * info.ConsensusGroupInfo.PerCount * info.ConsensusGroupInfo.Repeat;
end;

end.