unit V.Ledger.Consensus.Simple;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  V.Common.Types,
  V.Ledger.Consensus.Core.Group,
  V.Ledger.Consensus.Core.Algo,
  V.Ledger.Consensus.Result,
  V.Log15;

type
  TSimpleCs = class
  private
    FGroupInfo: TGroupInfo;
    FAlgo: IAlgo;
    FLog: ILogger;
    function VerifyProducer(t: TDateTime; address: TAddress; result: TElectionResult): Boolean;
  public
    constructor Create(log: ILogger);
    function GetInfo: TGroupInfo;
    function GenProofTime(h: UInt64): TDateTime;
    function ElectionTime(t: TDateTime): TTuple<TElectionResult, Error>;
    function ElectionIndex(index: UInt64): TTuple<TElectionResult, Error>;
    function VerifyProducer(address: TAddress; t: TDateTime): TTuple<Boolean, Error>;
  end;

function NewSimpleCs(log: ILogger): TSimpleCs;

var
  SimpleGenesis: TDateTime;
  SimpleAddrs: TArray<TAddress>;

implementation

uses
  System.DateUtils;

function GenSimpleAddrs: TArray<TAddress>;
var
  addrs: TArray<string>;
  v: string;
  addr: TAddress;
begin
  SetLength(Result, 0);
  addrs := ['vite_360232b0378111b122685a15e612143dc9a89cfa7e803f4b5a',
    'vite_ce18b99b46c70c8e6bf34177d0c5db956a8c3ea7040a1c1e25'];
  for v in addrs do
  begin
    addr := HexToAddress(v);
    Result := Result + [addr];
  end;
end;

function GenSimpleInfo: TGroupInfo;
var
  group: TConsensusGroupInfo;
begin
  group.Gid := GID_Snapshot;
  group.NodeCount := 2;
  group.Interval := 1;
  group.PerCount := 3;
  group.RandCount := 1;
  group.RandRank := 100;
  group.Repeat := 1;
  group.CountingTokenId := CreateTokenTypeId;
  group.RegisterConditionId := 0;
  group.RegisterConditionParam := nil;
  group.VoteConditionId := 0;
  group.VoteConditionParam := nil;
  group.Owner := Default(TAddress);
  group.StakeAmount := nil;
  group.ExpirationHeight := 0;

  Result := NewGroupInfo(SimpleGenesis, group);
end;

{ TSimpleCs }

constructor TSimpleCs.Create(log: ILogger);
begin
  FLog := log.New('gid', 'snapshot');
  FGroupInfo := GenSimpleInfo;
  FAlgo := NewAlgo(FGroupInfo);
end;

function TSimpleCs.ElectionIndex(index: UInt64): TTuple<TElectionResult, Error>;
var
  plans: TElectionResult;
begin
  plans := GenElectionResult(FGroupInfo, index, SimpleAddrs);
  Result := TTuple.Create(plans, nil);
end;

function TSimpleCs.ElectionTime(t: TDateTime): TTuple<TElectionResult, Error>;
var
  index: UInt64;
begin
  index := FGroupInfo.TimeIndex.Time2Index(t);
  Result := ElectionIndex(index);
end;

function TSimpleCs.GenProofTime(h: UInt64): TDateTime;
begin
  Result := FGroupInfo.TimeIndex.Index2Time(h).Item2;
end;

function TSimpleCs.GetInfo: TGroupInfo;
begin
  Result := FGroupInfo;
end;

function TSimpleCs.VerifyProducer(address: TAddress; t: TDateTime): TTuple<Boolean, Error>;
var
  electionResult: TElectionResult;
  err: Error;
begin
  Tuple.Create(electionResult, err) := ElectionTime(t);
  if err <> nil then
  begin
    Result := TTuple.Create(False, err);
    Exit;
  end;
  Result := TTuple.Create(VerifyProducer(t, address, electionResult), nil);
end;

function TSimpleCs.VerifyProducer(t: TDateTime; address: TAddress; result: TElectionResult): Boolean;
var
  plan: TMemberPlan;
begin
  Result := False;
  if result.Plans = nil then
    Exit;

  for plan in result.Plans do
  begin
    if (plan.Member = address) and (plan.STime = t) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function NewSimpleCs(log: ILogger): TSimpleCs;
begin
  Result := TSimpleCs.Create(log);
end;

initialization
  SimpleGenesis := UnixToDateTime(1553849738);
  SimpleAddrs := GenSimpleAddrs;
end.