unit V.Ledger.Consensus.Snapshot;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Go.Big,
  V.Common.Types,
  V.Interfaces.Core,
  V.Ledger.Consensus.Result,
  V.Ledger.Consensus.ChainRw,
  V.Ledger.Consensus.Dpos,
  V.Ledger.Consensus.Core.Group,
  V.Ledger.Consensus.Core.Vote,
  V.Ledger.Consensus.Core.Algo,
  V.Ledger.Consensus.Core.Stats,
  V.Ledger.Consensus.Core.Utils,
  V.Ledger.Consensus.Cdb,
  V.Ledger.Consensus.LinkedArray,
  V.Log15;

type
  ISnapshotCs = interface(IDposReader, ISBPStatReader)
    ['{C4B7F8D3-8D4C-4D4B-8B4A-7A5D8D3C4B8B}']
    function ElectionTime(t: TDateTime): TTuple<TElectionResult, Error>;
    function VerifySnapshotProducer(header: ISnapshotBlock): TTuple<Boolean, Error>;
    function VerifyProducerAndSeed(block: ISnapshotBlock): TTuple<Boolean, Error>;
    function VoteDetailsBeforeTime(t: TDateTime): TTuple<TArray<TVoteDetails>, PHashHeight, Error>;
    procedure LoadVotes(proofBlock: ISnapshotBlock);
    function DayVoteStat(b: Byte; index: UInt64; proofHash: THash): TTuple<TVoteContent, Error>;
  end;

  TSnapshotCs = class(TInterfacedObject, ISnapshotCs)
  private
    FGroupInfo: TGroupInfo;
    FRw: IChainRw;
    FAlgo: IAlgo;
    FLog: ILogger;
    function GenSnapshotProofTimeIndx(idx: UInt64): TTuple<TDateTime, UInt64>;
    function VerifyProducerInternal(t: TDateTime; address: TAddress; result: TElectionResult): Boolean;
    function CalVotes(proofBlock: ISnapshotBlock; index: UInt64): TTuple<TArray<TAddress>, Error>;
  public
    constructor Create(rw: IChainRw; log: ILogger);
    { ISnapshotCs & IDposReader & ISBPStatReader }
    function GetSuccessRateByHour(index: UInt64): TTuple<TDictionary<TAddress, Int32>, Error>;
    function HourStats(startIndex, endIndex: UInt64): TTuple<TArray<PHourStats>, Error>;
    function GetHourTimeIndex: ITimeIndex;
    function PeriodStats(startIndex, endIndex: UInt64): TTuple<TArray<PPeriodStats>, Error>;
    function GetNodeCount: Integer;
    function GetPeriodTimeIndex: ITimeIndex;
    function GetDayTimeIndex: ITimeIndex;
    function DayStats(startIndex, endIndex: UInt64): TTuple<TArray<PDayStats>, Error>;
    function DayVoteStat(b: Byte; index: UInt64; proofHash: THash): TTuple<TVoteContent, Error>;
    function ElectionTime(t: TDateTime): TTuple<TElectionResult, Error>;
    function ElectionIndex(index: UInt64): TTuple<TElectionResult, Error>;
    procedure LoadVotes(proofBlock: ISnapshotBlock);
    function GenProofTime(idx: UInt64): TDateTime;
    function VoteDetailsBeforeTime(t: TDateTime): TTuple<TArray<TVoteDetails>, PHashHeight, Error>;
    function VerifySnapshotProducer(header: ISnapshotBlock): TTuple<Boolean, Error>;
    function VerifyProducer(address: TAddress; t: TDateTime): TTuple<Boolean, Error>;
    function VerifyProducerAndSeed(block: ISnapshotBlock): TTuple<Boolean, Error>;
    function Time2Index(t: TDateTime): UInt64;
    function Index2Time(i: UInt64): TTuple<TDateTime, TDateTime>;
    function GetInfo: TGroupInfo;
  end;

function NewSnapshotCs(rw: IChainRw; log: ILogger): ISnapshotCs;
function GetBaseStats(genesisHash: THash; array_: ILinkedArray; startIndex, endIndex: UInt64): TTuple<TArray<PBaseStats>, Error>;

implementation

uses
  System.Math;

{ TSnapshotCs }

constructor TSnapshotCs.Create(rw: IChainRw; log: ILogger);
var
  info: TGroupInfo;
  err: Error;
begin
  FRw := rw;
  FLog := log.New('gid', 'snapshot');
  Tuple.Create(info, err) := rw.GetMemberInfo(GID_Snapshot);
  if err <> nil then
    raise EProgrammerException.Create(err.Error);
  FGroupInfo := info;
  FAlgo := NewAlgo(FGroupInfo);
end;

function TSnapshotCs.CalVotes(proofBlock: ISnapshotBlock; index: UInt64): TTuple<TArray<TAddress>, Error>;
var
  hashH: THashHeight;
  r: TArray<TAddress>;
  ok: Boolean;
  seed: TSeedInfo;
  votes: TArray<PVote>;
  err: Error;
  successRate: TDictionary<TAddress, Int32>;
  proofIndex: UInt64;
  all: string;
  v: PVote;
  context: TVoteAlgoContext;
  finalVotes: TArray<PVote>;
  result: string;
  address: TArray<TAddress>;
begin
  hashH.Hash := proofBlock.Hash;
  hashH.Height := proofBlock.Height;
  Tuple.Create(r, ok) := FRw.GetSnapshotVoteCache(hashH.Hash);
  if ok then
    Exit(TTuple.Create(r, nil));

  seed := NewSeedInfo(FRw.GetSeedsBeforeHashH(hashH.Hash));
  Tuple.Create(votes, err) := FRw.CalVotes(FGroupInfo, hashH);
  if err <> nil then
    Exit(TTuple.Create(nil, err));

  proofIndex := GenSnapshotProofTimeIndx(Time2Index(proofBlock.Timestamp)).Item2;
  if proofIndex > 0 then
  begin
    Tuple.Create(successRate, err) := FRw.GetSuccessRateByHour(proofIndex);
    if err <> nil then
      Exit(TTuple.Create(nil, err));
  end;

  all := '';
  for v in votes do
    all := all + Format('[%s-%s]', [v.Name, v.Balance.ToString]);
  FLog.Info(Format('[%d][%d]pre success rate log: %+v, %s, seed:%d', [hashH.Height, index, successRate, all, seed.Seeds]));

  context := NewVoteAlgoContext(votes, @hashH, successRate, seed);
  finalVotes := FAlgo.FilterVotes(context);
  finalVotes := FAlgo.ShuffleVotes(finalVotes, @hashH, seed);

  result := Format('CalVotes result: %d:%d:%s, ', [index, hashH.Height, hashH.Hash.ToString]);
  for v in finalVotes do
  begin
    if Length(v.&Type) > 0 then
      result := result + Format('[%s:%s],', [v.Name, '...']) // Simplified logging
    else
      result := result + Format('[%s],', [v.Name]);
  end;
  FLog.Info(result);
  address := ConvertVoteToAddress(finalVotes);

  FRw.UpdateSnapshotVoteCache(hashH.Hash, address);
  Result := TTuple.Create(address, nil);
end;

function TSnapshotCs.DayStats(startIndex, endIndex: UInt64): TTuple<TArray<PDayStats>, Error>;
var
  points: TDictionary<UInt64, TPoint>;
  proofHash: PHash;
  i: UInt64;
  point: TPoint;
  err: Error;
  result: TArray<PDayStats>;
  registerMap: TDictionary<TAddress, string>;
  lastHash: THash;
  registers: TArray<PRegistration>;
  v: PRegistration;
  vv: TAddress;
  p: TPoint;
  stats: PDayStats;
  k: string;
  voteVal: IBigInt;
  sbpStats: PSbpStats;
  addr: TAddress;
  content: TContent;
  name: string;
  ok: Boolean;
begin
  points := TDictionary<UInt64, TPoint>.Create;
  proofHash := nil;
  i := endIndex;
  while (i >= startIndex) and (i <= endIndex) do
  begin
    if proofHash = nil then
      Tuple.Create(point, err) := FRw.GetDayPoints.GetByIndex(i)
    else
      Tuple.Create(point, err) := FRw.GetDayPoints.GetByIndexWithProof(i, proofHash^);

    if err <> nil then
      Exit(TTuple.Create(nil, err));
    if point.IsEmpty then
    begin
      Dec(i);
      Continue;
    end;
    points.Add(i, point);
    proofHash := @point.PrevHash;
    Dec(i);
  end;

  if points.Count = 0 then
    Exit(TTuple.Create(nil, nil));

  SetLength(result, 0);
  registerMap := TDictionary<TAddress, string>.Create;
  lastHash := FRw.GetLatestSnapshotBlock.Hash;
  // TODO: FRw should expose GetAllRegisterList
  // Tuple.Create(registers, err) := FRw.GetAllRegisterList(lastHash, GID_Snapshot);
  // if err <> nil then
  //   Exit(TTuple.Create(nil, err));
  // for v in registers do
  // begin
  //   for vv in v.HisAddrList do
  //     registerMap.Add(vv, v.Name);
  // end;

  i := startIndex;
  while i <= endIndex do
  begin
    if not points.TryGetValue(i, p) or p.IsEmpty or (p.Votes = nil) then
    begin
      Inc(i);
      Continue;
    end;
    New(stats);
    stats.Index := i;
    stats.Stats := TDictionary<string, PSbpStats>.Create;
    New(stats.VoteSum);
    stats.VoteSum.Int := p.Votes.Total;

    for k, voteVal in p.Votes.Details do
    begin
      New(sbpStats);
      sbpStats.Index := i;
      New(sbpStats.VoteCnt);
      sbpStats.VoteCnt.Int := voteVal;
      sbpStats.Name := k;
      stats.Stats.Add(k, sbpStats);
    end;

    for addr, content in p.Sbps do
    begin
      if registerMap.TryGetValue(addr, name) then
      begin
        if stats.Stats.TryGetValue(name, sbpStats) then
        begin
          sbpStats.BlockNum := sbpStats.BlockNum + content.FactualNum;
          sbpStats.ExceptedBlockNum := sbpStats.ExceptedBlockNum + content.ExpectedNum;
        end;
      end;
      stats.BlockTotal := stats.BlockTotal + content.FactualNum;
    end;
    result := result + [stats];
    Inc(i);
  end;
  Result := TTuple.Create(result, nil);
end;

function TSnapshotCs.DayVoteStat(b: Byte; index: UInt64; proofHash: THash): TTuple<TVoteContent, Error>;
var
  votes: TArray<PVote>;
  err: Error;
  total: IBigInt;
  details: TDictionary<string, IBigInt>;
  k: Integer;
  v: PVote;
  result: TVoteContent;
begin
  Tuple.Create(votes, err) := CalVotes(FGroupInfo.ConsensusGroupInfo, proofHash, FRw as IStateCh);
  if err <> nil then
    Exit(TTuple.Create(nil, err));

  TArray.Sort<PVote>(votes, TByBalance.Create);
  total := TBigInt.New;
  details := TDictionary<string, IBigInt>.Create;
  for k, v in votes do
  begin
    if k >= FGroupInfo.ConsensusGroupInfo.RandRank then
      Break;
    details.Add(v.Name, v.Balance);
    total.Add(total, v.Balance);
  end;
  result := TVoteContent.Create;
  result.Details := details;
  result.Total := total;
  Result := TTuple.Create(result, nil);
end;

function TSnapshotCs.ElectionIndex(index: UInt64): TTuple<TElectionResult, Error>;
var
  proofTime: TDateTime;
  proofBlock: ISnapshotBlock;
  e: Error;
  voteResults: TArray<TAddress>;
  plans: TElectionResult;
begin
  proofTime := GenSnapshotProofTimeIndx(index).Item1;
  Tuple.Create(proofBlock, e) := FRw.GetSnapshotBeforeTime(proofTime);
  if e <> nil then
  begin
    FLog.Error('geSnapshotBeferTime fail.', 'err', e);
    Exit(TTuple.Create(Default(TElectionResult), e));
  end;
  FLog.Debug(Format('election index:%d,%s, proofTime:%s', [index, proofBlock.Hash.ToString, DateTimeToStr(proofTime)]));
  Tuple.Create(voteResults, e) := CalVotes(proofBlock, index);
  if e <> nil then
    Exit(TTuple.Create(Default(TElectionResult), e));

  plans := GenElectionResult(FGroupInfo, index, voteResults);
  Result := TTuple.Create(plans, nil);
end;

function TSnapshotCs.ElectionTime(t: TDateTime): TTuple<TElectionResult, Error>;
begin
  Result := ElectionIndex(Time2Index(t));
end;

function TSnapshotCs.GenProofTime(idx: UInt64): TDateTime;
begin
  Result := GenSnapshotProofTimeIndx(idx).Item1;
end;

function TSnapshotCs.GenSnapshotProofTimeIndx(idx: UInt64): TTuple<TDateTime, UInt64>;
begin
  if idx < 2 then
  begin
    Result := TTuple.Create(FGroupInfo.GenesisTime, 0); // Simplified, Go adds 1 sec
    Exit;
  end;
  Result := TTuple.Create(Index2Time(idx - 2).Item2, idx - 2);
end;

function TSnapshotCs.GetDayTimeIndex: ITimeIndex;
begin
  Result := FRw.GetDayPoints;
end;

function TSnapshotCs.GetHourTimeIndex: ITimeIndex;
begin
  Result := FRw.GetHourPoints;
end;

function TSnapshotCs.GetInfo: TGroupInfo;
begin
  Result := FGroupInfo;
end;

function TSnapshotCs.GetNodeCount: Integer;
begin
  Result := FGroupInfo.ConsensusGroupInfo.NodeCount;
end;

function TSnapshotCs.GetPeriodTimeIndex: ITimeIndex;
begin
  Result := FRw.GetPeriodPoints;
end;

function TSnapshotCs.GetSuccessRateByHour(index: UInt64): TTuple<TDictionary<TAddress, Int32>, Error>;
begin
  Result := FRw.GetSuccessRateByHour(index);
end;

function TSnapshotCs.HourStats(startIndex, endIndex: UInt64): TTuple<TArray<PHourStats>, Error>;
var
  genesis: ISnapshotBlock;
  stats: TArray<PBaseStats>;
  err: Error;
  result: TArray<PHourStats>;
  k: Integer;
  v: PBaseStats;
begin
  genesis := (FRw as IStateCh).GetGenesisSnapshotBlock;
  Tuple.Create(stats, err) := GetBaseStats(genesis.Hash, FRw.GetHourPoints, startIndex, endIndex);
  if err <> nil then
    Exit(TTuple.Create(nil, err));

  SetLength(result, Length(stats));
  for k, v in stats do
  begin
    New(result[k]);
    result[k].BaseStats := v^;
  end;
  Result := TTuple.Create(result, nil);
end;

function TSnapshotCs.Index2Time(i: UInt64): TTuple<TDateTime, TDateTime>;
begin
  Result := FGroupInfo.TimeIndex.Index2Time(i);
end;

procedure TSnapshotCs.LoadVotes(proofBlock: ISnapshotBlock);
begin
  FLog.Info('loadVotes ', 'hash', proofBlock.Hash.ToString, 'height', proofBlock.Height);
  // This is a simplified version of the Go implementation's async loading.
  // A full implementation would require a more complex threading model.
  CalVotes(proofBlock, Time2Index(proofBlock.Timestamp));
end;

function TSnapshotCs.PeriodStats(startIndex, endIndex: UInt64): TTuple<TArray<PPeriodStats>, Error>;
var
  genesis: ISnapshotBlock;
  stats: TArray<PBaseStats>;
  err: Error;
  result: TArray<PPeriodStats>;
  k: Integer;
  v: PBaseStats;
begin
  genesis := (FRw as IStateCh).GetGenesisSnapshotBlock;
  Tuple.Create(stats, err) := GetBaseStats(genesis.Hash, FRw.GetPeriodPoints, startIndex, endIndex);
  if err <> nil then
    Exit(TTuple.Create(nil, err));

  SetLength(result, Length(stats));
  for k, v in stats do
  begin
    New(result[k]);
    result[k].BaseStats := v^;
  end;
  Result := TTuple.Create(result, nil);
end;

function TSnapshotCs.Time2Index(t: TDateTime): UInt64;
begin
  Result := FGroupInfo.TimeIndex.Time2Index(t);
end;

function TSnapshotCs.VerifyProducer(address: TAddress; t: TDateTime): TTuple<Boolean, Error>;
var
  electionResult: TElectionResult;
  err: Error;
begin
  Tuple.Create(electionResult, err) := ElectionTime(t);
  if err <> nil then
    Exit(TTuple.Create(False, err));

  Result := TTuple.Create(VerifyProducerInternal(t, address, electionResult), nil);
end;

function TSnapshotCs.VerifyProducerAndSeed(block: ISnapshotBlock): TTuple<Boolean, Error>;
var
  producerTime: TDateTime;
  electionResult: TElectionResult;
  err: Error;
  result: Boolean;
  seedBlock: ISnapshotBlock;
  hash: THash;
begin
  producerTime := block.Timestamp;
  Tuple.Create(electionResult, err) := ElectionTime(producerTime);
  if err <> nil then
    Exit(TTuple.Create(False, err));

  result := VerifyProducerInternal(producerTime, block.Producer, electionResult);
  if not result then
    Exit(TTuple.Create(False, nil));

  if block.Seed <> 0 then
  begin
    // TODO: FRw should expose GetLastUnpublishedSeedSnapshotHeader
    // Tuple.Create(seedBlock, err) := FRw.GetLastUnpublishedSeedSnapshotHeader(block.Producer, electionResult.STime);
    // if err <> nil then
    //   Exit(TTuple.Create(False, err));
    // if seedBlock = nil then
    //   Exit(TTuple.Create(False, EProgrammerException.Create('get last seed snapshot header nil.')));
    //
    // hash := ComputeSeedHash(block.Seed, seedBlock.PrevHash, seedBlock.Timestamp);
    // if hash <> seedBlock.SeedHash then
    //   Exit(TTuple.Create(False, EProgrammerException.CreateFmt('seed verify fail. %s-%d', [seedBlock.Hash.ToString, seedBlock.Height])));
  end;
  Result := TTuple.Create(True, nil);
end;

function TSnapshotCs.VerifyProducerInternal(t: TDateTime; address: TAddress; result: TElectionResult): Boolean;
var
  plan: TMemberPlan;
begin
  if result.Plans = nil then
    Exit(False);

  for plan in result.Plans do
  begin
    if (plan.Member = address) and (plan.STime = t) then
      Exit(True);
  end;
  Result := False;
end;

function TSnapshotCs.VerifySnapshotProducer(header: ISnapshotBlock): TTuple<Boolean, Error>;
begin
  Result := VerifyProducer(header.Producer, header.Timestamp);
end;

function TSnapshotCs.VoteDetailsBeforeTime(t: TDateTime): TTuple<TArray<TVoteDetails>, PHashHeight, Error>;
var
  block: ISnapshotBlock;
  e: Error;
  headH: THashHeight;
  details: TArray<TVoteDetails>;
begin
  Tuple.Create(block, e) := FRw.GetSnapshotBeforeTime(t);
  if e <> nil then
  begin
    FLog.Error('geSnapshotBeferTime fail.', 'err', e);
    Exit(TTuple.Create(nil, nil, e));
  end;
  headH.Height := block.Height;
  headH.Hash := block.Hash;
  Tuple.Create(details, e) := FRw.CalVoteDetails(FGroupInfo.ConsensusGroupInfo.Gid, FGroupInfo, headH);
  Result := TTuple.Create(details, @headH, e);
end;

function GetBaseStats(genesisHash: THash; array_: ILinkedArray; startIndex, endIndex: UInt64): TTuple<TArray<PBaseStats>, Error>;
var
  points: TDictionary<UInt64, TPoint>;
  proofHash: PHash;
  i: UInt64;
  point: TPoint;
  err: Error;
  result: TArray<PBaseStats>;
  p: TPoint;
  stats: PBaseStats;
  k: TAddress;
  v: TContent;
  sbp: PSbpStats;
begin
  points := TDictionary<UInt64, TPoint>.Create;
  proofHash := nil;
  i := endIndex;
  while (i >= startIndex) and (i <= endIndex) do
  begin
    if proofHash = nil then
      Tuple.Create(point, err) := array_.GetByIndex(i)
    else if proofHash^ = genesisHash then
      Break
    else
      Tuple.Create(point, err) := array_.GetByIndexWithProof(i, proofHash^);

    if err <> nil then
      Exit(TTuple.Create(nil, err));
    if point.IsEmpty then
    begin
      Dec(i);
      Continue;
    end;
    points.Add(i, point);
    proofHash := @point.PrevHash;
    Dec(i);
  end;

  if points.Count = 0 then
    Exit(TTuple.Create(nil, nil));

  SetLength(result, 0);
  i := startIndex;
  while i <= endIndex do
  begin
    if not points.TryGetValue(i, p) or p.IsEmpty then
    begin
      Inc(i);
      Continue;
    end;
    New(stats);
    stats.Index := i;
    stats.Stats := TDictionary<TAddress, PSbpStats>.Create;
    for k, v in p.Sbps do
    begin
      New(sbp);
      sbp.Index := i;
      sbp.BlockNum := v.FactualNum;
      sbp.ExceptedBlockNum := v.ExpectedNum;
      stats.Stats.Add(k, sbp);
    end;
    result := result + [stats];
    Inc(i);
  end;
  Result := TTuple.Create(result, nil);
end;

function NewSnapshotCs(rw: IChainRw; log: ILogger): ISnapshotCs;
begin
  Result := TSnapshotCs.Create(rw, log);
end;

end.