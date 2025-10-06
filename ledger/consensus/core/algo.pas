unit V.Ledger.Consensus.Core.Algo;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  V.Common.Types,
  V.Interfaces.Core,
  V.Ledger.Consensus.Core.Vote,
  V.Ledger.Consensus.Core.Group;

type
  TSeedInfo = class
  public
    Seeds: UInt64;
    constructor Create(seed: UInt64);
  end;

  TVoteAlgoContext = class
  public
    Votes: TArray<PVote>;
    HashH: PHashHeight;
    SuccessRate: TDictionary<TAddress, Int32>;
    Seeds: TSeedInfo;
    SBPs: TArray<PVote>;
    constructor Create(votes: TArray<PVote>; hashH: PHashHeight; successRate: TDictionary<TAddress, Int32>; seeds: TSeedInfo);
  end;

  IAlgo = interface
    ['{D1E2F3A4-B5C6-4A8B-9C8D-7E6F5A4B3C2D}']
    function ShuffleVotes(votes: TArray<PVote>; hashH: PHashHeight; info: TSeedInfo): TArray<PVote>;
    function FilterVotes(context: TVoteAlgoContext): TArray<PVote>;
    function FilterSimple(votes: TArray<PVote>): TTuple<TArray<PVote>, TArray<PVote>>;
  end;

  TAlgo = class(TInterfacedObject, IAlgo)
  private
    FInfo: TGroupInfo;
    function FindSeedTmp(votes: TArray<PVote>; sheight: UInt64; info: TSeedInfo; successRate: TDictionary<TAddress, Int32>): Int64;
    function FindSeed(votes: TArray<PVote>; sheight: UInt64; info: TSeedInfo): Int64;
    function CalRandCnt(total, randNum: Integer): Integer;
    function FilterRand(votes: TArray<PVote>; hashH: PHashHeight; seedInfo: TSeedInfo): TArray<PVote>;
    function FilterRandV2(groupA, groupB: TArray<PVote>; hashH: PHashHeight; seedInfo: TSeedInfo; successRate: TDictionary<TAddress, Int32>): TArray<PVote>;
    function FilterBySuccessRate(groupA, groupB: TArray<PVote>; height: PHashHeight; successRate: TDictionary<TAddress, Int32>): TTuple<TArray<PVote>, TArray<PVote>>;
    function CheckValid(groupA, groupB: TArray<PVote>): Error;
  public
    constructor Create(info: TGroupInfo);
    function ShuffleVotes(votes: TArray<PVote>; hashH: PHashHeight; info: TSeedInfo): TArray<PVote>;
    function FilterVotes(context: TVoteAlgoContext): TArray<PVote>;
    function FilterSimple(votes: TArray<PVote>): TTuple<TArray<PVote>, TArray<PVote>>;
  end;

  TSuccessRateVote = class
  public
    Vote: PVote;
    Rate: Int32;
  end;

  TBySuccessRate = class(TComparer<TSuccessRateVote>)
  public
    function Compare(const Left, Right: TSuccessRateVote): Integer; override;
  end;

function NewSeedInfo(seed: UInt64): TSeedInfo;
function NewVoteAlgoContext(votes: TArray<PVote>; hashH: PHashHeight; successRate: TDictionary<TAddress, Int32>; seeds: TSeedInfo): TVoteAlgoContext;
function NewAlgo(info: TGroupInfo): IAlgo;
function MergeGroup(groupA, groupB: TArray<PVote>): TArray<PVote>;

const
  Line = 800000;

implementation

uses
  Go.Big,
  Go.Rand,
  System.Math;

{ TSeedInfo }

constructor TSeedInfo.Create(seed: UInt64);
begin
  Seeds := seed;
end;

{ TVoteAlgoContext }

constructor TVoteAlgoContext.Create(votes: TArray<PVote>; hashH: PHashHeight; successRate: TDictionary<TAddress, Int32>; seeds: TSeedInfo);
begin
  Self.Votes := votes;
  Self.HashH := hashH;
  if successRate = nil then
    Self.SuccessRate := TDictionary<TAddress, Int32>.Create
  else
    Self.SuccessRate := successRate;
  Self.Seeds := seeds;
end;

{ TAlgo }

function TAlgo.CalRandCnt(total, randNum: Integer): Integer;
begin
  if total div 3 > randNum then
    Result := randNum
  else
    Result := total div 3;
end;

function TAlgo.CheckValid(groupA, groupB: TArray<PVote>): Error;
var
  lenA, lenB: Integer;
begin
  lenA := Length(groupA);
  lenB := Length(groupB);
  if lenA > FInfo.ConsensusGroupInfo.NodeCount then
  begin
    Result := EProgrammerException.CreateFmt('groupA''s size[%d] must <= %d.', [lenA, FInfo.ConsensusGroupInfo.NodeCount]);
    Exit;
  end;
  if (lenA < FInfo.ConsensusGroupInfo.NodeCount) and (lenB > 0) then
  begin
    Result := EProgrammerException.CreateFmt('groupB''s size[%d] should be zero.', [lenB]);
    Exit;
  end;
  if lenB + lenA > FInfo.ConsensusGroupInfo.RandRank then
  begin
    Result := EProgrammerException.CreateFmt('the sum of groupA[%d] and groupB[%d] must <= %d.', [lenA, lenB, FInfo.ConsensusGroupInfo.RandRank]);
    Exit;
  end;
  Result := nil;
end;

constructor TAlgo.Create(info: TGroupInfo);
begin
  FInfo := info;
end;

function TAlgo.FilterBySuccessRate(groupA, groupB: TArray<PVote>; height: PHashHeight; successRate: TDictionary<TAddress, Int32>): TTuple<TArray<PVote>, TArray<PVote>>;
const
  ObsoletedNum = 2;
var
  groupA1, deleteGroupA, improvementGroupB, groupB1: TArray<TSuccessRateVote>;
  successRateGroupA, successRateGroupB: TArray<TSuccessRateVote>;
  v: PVote;
  rate: Int32;
  vote: TSuccessRateVote;
  tmps: TArray<TSuccessRateVote>;
  i, lenA: Integer;
  demotion, promotion: TSuccessRateVote;
  resultGroupA, resultGroupB: TArray<PVote>;
  srv: TSuccessRateVote;
begin
  if Length(groupB) = 0 then
  begin
    Result := TTuple.Create(groupA, groupB);
    Exit;
  end;

  if successRate.Count < ObsoletedNum then
  begin
    Result := TTuple.Create(groupA, groupB);
    Exit;
  end;

  // groupA
  SetLength(successRateGroupA, 0);
  for v in groupA do
  begin
    if not successRate.TryGetValue(v.Addr, rate) then
      rate := -1;
    vote := TSuccessRateVote.Create;
    vote.Vote := v;
    vote.Rate := rate;
    successRateGroupA := successRateGroupA + [vote];
  end;
  TArray.Sort<TSuccessRateVote>(successRateGroupA, TBySuccessRate.Create);

  SetLength(groupA1, 0);
  SetLength(deleteGroupA, 0);
  tmps := Copy(successRateGroupA, Length(successRateGroupA) - ObsoletedNum, ObsoletedNum);

  for vote in Copy(successRateGroupA, 0, Length(successRateGroupA) - ObsoletedNum) do
    groupA1 := groupA1 + [vote];

  for vote in tmps do
  begin
    if (vote.Rate >= 0) and (vote.Rate < Line) then
      deleteGroupA := deleteGroupA + [vote]
    else
      groupA1 := groupA1 + [vote];
  end;

  // groupB
  SetLength(successRateGroupB, 0);
  for v in groupB do
  begin
    if not successRate.TryGetValue(v.Addr, rate) then
      rate := -1;
    vote := TSuccessRateVote.Create;
    vote.Vote := v;
    vote.Rate := rate;
    successRateGroupB := successRateGroupB + [vote];
  end;
  TArray.Sort<TSuccessRateVote>(successRateGroupB, TBySuccessRate.Create);

  SetLength(improvementGroupB, 0);
  SetLength(groupB1, 0);
  for vote in successRateGroupB do
  begin
    if Length(improvementGroupB) >= ObsoletedNum then
    begin
      groupB1 := groupB1 + [vote];
      Continue;
    end;
    if vote.Rate > Line then
      improvementGroupB := improvementGroupB + [vote]
    else
      groupB1 := groupB1 + [vote];
  end;

  // exchange
  for i := 1 to ObsoletedNum do
  begin
    lenA := Length(deleteGroupA);
    if (lenA < i) or (Length(improvementGroupB) < i) then
      Break;
    demotion := deleteGroupA[lenA - i];
    promotion := improvementGroupB[i - 1];
    promotion.Vote.&Type := promotion.Vote.&Type + [TVoteType.SUCCESS_RATE_PROMOTION];
    demotion.Vote.&Type := demotion.Vote.&Type + [TVoteType.SUCCESS_RATE_DEMOTION];
    deleteGroupA[lenA - i] := promotion;
    improvementGroupB[i - 1] := demotion;
  end;

  SetLength(resultGroupA, 0);
  SetLength(resultGroupB, 0);

  for srv in groupA1 do resultGroupA := resultGroupA + [srv.Vote];
  for srv in deleteGroupA do resultGroupA := resultGroupA + [srv.Vote];
  for srv in groupB1 do resultGroupB := resultGroupB + [srv.Vote];
  for srv in improvementGroupB do resultGroupB := resultGroupB + [srv.Vote];

  Result := TTuple.Create(resultGroupA, resultGroupB);
end;

function TAlgo.FilterRand(votes: TArray<PVote>; hashH: PHashHeight; seedInfo: TSeedInfo): TArray<PVote>;
var
  total, length, randCnt, topTotal, leftTotal, i, r: Integer;
  seed: Int64;
  randMembers: TArray<Boolean>;
  random: IRand;
  k: Integer;
  b: Boolean;
begin
  total := FInfo.ConsensusGroupInfo.NodeCount;
  TArray.Sort<PVote>(votes, TByBalance.Create);
  length := Length(votes);
  if length < total then
  begin
    Result := votes;
    Exit;
  end;

  seed := FindSeed(votes, hashH.Height, seedInfo);
  randCnt := CalRandCnt(total, FInfo.ConsensusGroupInfo.RandCount);
  topTotal := total - randCnt;
  leftTotal := length - topTotal;
  SetLength(randMembers, leftTotal);
  random := TRand.New(TRand.NewSource(seed));

  i := 0;
  while i < randCnt do
  begin
    r := random.Intn(leftTotal);
    if randMembers[r] then
      Continue
    else
    begin
      randMembers[r] := True;
      Inc(i);
    end;
  end;

  Result := Copy(votes, 0, topTotal);
  for k, b in randMembers do
  begin
    if b then
      Result := Result + [votes[k + topTotal]];
  end;
end;

function TAlgo.FilterRandV2(groupA, groupB: TArray<PVote>; hashH: PHashHeight; seedInfo: TSeedInfo; successRate: TDictionary<TAddress, Int32>): TArray<PVote>;
var
  total, length, randCnt, topTotal: Integer;
  seed: Int64;
  random1, random2: IRand;
  firstArr, secondArr, arr: TArray<Integer>;
  v: Integer;
  promotion: PVote;
begin
  if Length(groupB) = 0 then
  begin
    Result := groupA;
    Exit;
  end;

  SetLength(Result, 0);
  total := FInfo.ConsensusGroupInfo.NodeCount;
  TArray.Sort<PVote>(groupA, TByBalance.Create);
  TArray.Sort<PVote>(groupB, TByBalance.Create);
  length := Length(groupA) + Length(groupB);

  seed := FindSeed(MergeGroup(groupA, groupB), hashH.Height, seedInfo);
  randCnt := CalRandCnt(total, FInfo.ConsensusGroupInfo.RandCount);
  topTotal := total - randCnt;

  if (topTotal * (length - total)) > (randCnt * total) then
  begin
    random1 := TRand.New(TRand.NewSource(seed));
    random2 := TRand.New(TRand.NewSource(seed + 1));
    firstArr := random1.Perm(total);
    firstArr := Copy(firstArr, 0, topTotal);
    secondArr := random2.Perm(length - total);
    secondArr := Copy(secondArr, 0, randCnt);

    for v in firstArr do Result := Result + [groupA[v]];
    for v in secondArr do
    begin
      promotion := groupB[v];
      promotion.&Type := promotion.&Type + [TVoteType.RANDOM_PROMOTION];
      Result := Result + [promotion];
    end;
  end
  else
  begin
    random1 := TRand.New(TRand.NewSource(seed));
    arr := random1.Perm(length);
    arr := Copy(arr, 0, total);
    for v in arr do
    begin
      if v >= total then
      begin
        promotion := groupB[v - total];
        promotion.&Type := promotion.&Type + [TVoteType.RANDOM_PROMOTION];
        Result := Result + [promotion];
      end
      else
        Result := Result + [groupA[v]];
    end;
  end;
end;

function TAlgo.FilterSimple(votes: TArray<PVote>): TTuple<TArray<PVote>, TArray<PVote>>;
var
  groupA, groupB: TArray<PVote>;
begin
  if Length(votes) <= FInfo.ConsensusGroupInfo.NodeCount then
  begin
    Result := TTuple.Create(votes, nil);
    Exit;
  end;

  groupA := Copy(votes, 0, FInfo.ConsensusGroupInfo.NodeCount);
  TArray.Sort<PVote>(votes, TByBalance.Create);

  if Length(votes) <= FInfo.ConsensusGroupInfo.RandRank then
    groupB := Copy(votes, FInfo.ConsensusGroupInfo.NodeCount, Length(votes) - FInfo.ConsensusGroupInfo.NodeCount)
  else
    groupB := Copy(votes, FInfo.ConsensusGroupInfo.NodeCount, FInfo.ConsensusGroupInfo.RandRank - FInfo.ConsensusGroupInfo.NodeCount);

  Result := TTuple.Create(groupA, groupB);
end;

function TAlgo.FilterVotes(context: TVoteAlgoContext): TArray<PVote>;
var
  votes, groupA, groupB: TArray<PVote>;
begin
  votes := context.Votes;
  Tuple.Create(groupA, groupB) := FilterSimple(votes);
  context.SBPs := MergeGroup(groupA, groupB);

  if Length(groupB) = 0 then
  begin
    TArray.Sort<PVote>(groupA, TByBalance.Create);
    Result := groupA;
    Exit;
  end;

  if context.SuccessRate <> nil then
    Tuple.Create(groupA, groupB) := FilterBySuccessRate(groupA, groupB, context.HashH, context.SuccessRate);

  votes := FilterRandV2(groupA, groupB, context.HashH, context.Seeds, context.SuccessRate);
  TArray.Sort<PVote>(votes, TByBalance.Create);
  Result := votes;
end;

function TAlgo.FindSeed(votes: TArray<PVote>; sheight: UInt64; info: TSeedInfo): Int64;
var
  result: IBigInt;
  v: PVote;
begin
  if info.Seeds = 0 then
  begin
    result := TBigInt.New;
    for v in votes do
      result.Add(result, v.Balance);
    result.Add(result, TBigInt.New(sheight));
    Result := result.Add(result, FInfo.Seed).Int64;
    Exit;
  end;

  result := TBigInt.New;
  result.Add(result, TBigInt.New(info.Seeds));
  result.Add(result, TBigInt.New(sheight));
  Result := result.Add(result, FInfo.Seed).Int64;
end;

function TAlgo.FindSeedTmp(votes: TArray<PVote>; sheight: UInt64; info: TSeedInfo; successRate: TDictionary<TAddress, Int32>): Int64;
var
  result: IBigInt;
  seeds: UInt64;
  v: PVote;
  rate: Int32;
begin
  result := TBigInt.New;
  result.Add(result, TBigInt.New(sheight));
  seeds := info.Seeds;
  if seeds = 0 then
  begin
    for v in votes do
      result.Add(result, v.Balance);
  end;
  if successRate <> nil then
  begin
    for rate in successRate.Values do
      result.Add(result, TBigInt.New(rate));
  end;
  result.Add(result, TBigInt.New(seeds));
  Result := result.Add(result, FInfo.Seed).Int64;
end;

function TAlgo.ShuffleVotes(votes: TArray<PVote>; hashH: PHashHeight; info: TSeedInfo): TArray<PVote>;
var
  seed: Int64;
  l: Integer;
  random: IRand;
  perm: TArray<Integer>;
  v: Integer;
begin
  seed := FindSeed(votes, hashH.Height, info);
  l := Length(votes);
  random := TRand.New(TRand.NewSource(seed));
  perm := random.Perm(l);

  SetLength(Result, l);
  for v in perm do
    Result[v] := votes[v];
end;

{ TBySuccessRate }

function TBySuccessRate.Compare(const Left, Right: TSuccessRateVote): Integer;
var
  r0, r: Integer;
begin
  r0 := Right.Rate - Left.Rate;
  if r0 = 0 then
  begin
    r := Right.Vote.Balance.Cmp(Left.Vote.Balance);
    if r = 0 then
      Result := AnsiString.Compare(Left.Vote.Name, Right.Vote.Name)
    else
      Result := r;
  end
  else
    Result := r0;
end;

function MergeGroup(groupA, groupB: TArray<PVote>): TArray<PVote>;
var
  lenA, i: Integer;
  v: PVote;
begin
  lenA := Length(groupA);
  SetLength(Result, lenA + Length(groupB));
  for i, v in groupA do Result[i] := v;
  for i, v in groupB do Result[i + lenA] := v;
end;

function NewAlgo(info: TGroupInfo): IAlgo;
begin
  Result := TAlgo.Create(info);
end;

function NewSeedInfo(seed: UInt64): TSeedInfo;
begin
  Result := TSeedInfo.Create(seed);
end;

function NewVoteAlgoContext(votes: TArray<PVote>; hashH: PHashHeight; successRate: TDictionary<TAddress, Int32>; seeds: TSeedInfo): TVoteAlgoContext;
begin
  Result := TVoteAlgoContext.Create(votes, hashH, successRate, seeds);
end;

end.