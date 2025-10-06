unit V.Ledger.Consensus.PeriodLinkedArray;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  V.Common.Types,
  V.Interfaces.Core,
  V.Ledger.Consensus.Core.TimeIndexer,
  V.Ledger.Consensus.Cdb,
  V.Ledger.Consensus.LinkedArray,
  V.Ledger.Consensus.Dpos,
  V.Ledger.Consensus.RollbackProof,
  V.Ledger.Chain.Interface,
  V.Ledger.Consensus.Result,
  V.LRU,
  V.Log15;

type
  TSBPInfo = record
    ExpectedNum: Int32;
    FactualNum: Int32;
  end;

  TPeriodLinkedArray = class(TInterfacedObject, ILinkedArray)
  private
    FTimeIndex: ITimeIndex;
    FPeriods: ILRUCache;
    FRw: IChain;
    FSnapshot: IDposReader;
    FProof: IRollbackProof;
    FLog: ILogger;
    function GetByIndexWithProofFromDb(index: UInt64; proofHash: THash): TTuple<TPoint, Error>;
    function GetByIndexWithProofFromChain(index: UInt64; proofHash: THash): TTuple<TPoint, Error>;
    function Set(index: UInt64; block: TPoint): Error;
    function GenPeriodPoint(index: UInt64; stime, etime: PDateTime; proofHash: THash; blocks: TArray<ISnapshotBlock>; result: TElectionResult): TTuple<TPoint, Error>;
  public
    constructor Create(rw: IChain; cs: IDposReader; proof: IRollbackProof; log: ILogger);
    { ITimeIndex }
    function Time2Index(t: TDateTime): UInt64;
    function Index2Time(i: UInt64): TTuple<TDateTime, TDateTime>;
    { ILinkedArray }
    function GetByIndex(index: UInt64): TTuple<TPoint, Error>;
    function GetByIndexWithProof(index: UInt64; proofHash: THash): TTuple<TPoint, Error>;
  end;

function NewPeriodPointArray(rw: IChain; cs: IDposReader; proof: IRollbackProof; log: ILogger): ILinkedArray;

implementation

uses
  System.DateUtils,
  System.JSON;

{ TPeriodLinkedArray }

constructor TPeriodLinkedArray.Create(rw: IChain; cs: IDposReader; proof: IRollbackProof; log: ILogger);
var
  cache: ILRUCache;
  err: Error;
  info: TGroupInfo;
  interval: TTimeSpan;
begin
  Tuple.Create(cache, err) := NewLRU(4 * 24 * 60);
  if err <> nil then
    raise EProgrammerException.Create(err.Error);

  info := cs.GetInfo;
  interval := TTimeSpan.FromSeconds(info.PlanInterval);
  FTimeIndex := NewTimeIndex(info.GenesisTime, interval);
  FRw := rw;
  FPeriods := cache;
  FSnapshot := cs;
  FLog := log;
  FProof := proof;
end;

function TPeriodLinkedArray.GenPeriodPoint(index: UInt64; stime, etime: PDateTime; proofHash: THash; blocks: TArray<ISnapshotBlock>; result: TElectionResult): TTuple<TPoint, Error>;
var
  point: TPoint;
  v: ISnapshotBlock;
  sbp: TContent;
  plan: TMemberPlan;
begin
  if proofHash <> blocks[0].Hash then
  begin
    Result := TTuple.Create(nil, EProgrammerException.CreateFmt('gen period point fail[%s][%s]', [proofHash.ToString, blocks[0].Hash.ToString]));
    Exit;
  end;
  point := TPoint.NewEmptyPoint(proofHash);

  point.PrevHash := blocks[High(blocks)].PrevHash;
  point.Hash := blocks[0].Hash;
  for v in blocks do
  begin
    if not point.Sbps.TryGetValue(v.Producer, sbp) then
    begin
      sbp := TContent.Create;
      sbp.FactualNum := 1;
      sbp.ExpectedNum := 0;
      point.Sbps.Add(v.Producer, sbp);
    end
    else
      sbp.AddNum(0, 1);
  end;

  for plan in result.Plans do
  begin
    if not point.Sbps.TryGetValue(plan.Member, sbp) then
    begin
      sbp := TContent.Create;
      sbp.FactualNum := 0;
      sbp.ExpectedNum := 1;
      point.Sbps.Add(plan.Member, sbp);
    end
    else
      sbp.AddNum(1, 0);
  end;
  Result := TTuple.Create(point, nil);
end;

function TPeriodLinkedArray.GetByIndex(index: UInt64): TTuple<TPoint, Error>;
var
  etime: TDateTime;
  proofHash: THash;
  err: Error;
begin
  etime := Index2Time(index).Item2;
  Tuple.Create(proofHash, err) := FProof.ProofHash(etime);
  if err <> nil then
  begin
    Result := TTuple.Create(nil, err);
    Exit;
  end;
  Result := GetByIndexWithProof(index, proofHash);
end;

function TPeriodLinkedArray.GetByIndexWithProof(index: UInt64; proofHash: THash): TTuple<TPoint, Error>;
var
  point: TPoint;
  err: Error;
begin
  if FRw.IsGenesisSnapshotBlock(proofHash) then
  begin
    Result := TTuple.Create(TPoint.NewEmptyPoint(proofHash), nil);
    Exit;
  end;

  Tuple.Create(point, err) := GetByIndexWithProofFromDb(index, proofHash);
  if err <> nil then
  begin
    Result := TTuple.Create(nil, err);
    Exit;
  end;
  if point <> nil then
  begin
    Result := TTuple.Create(point, nil);
    Exit;
  end;

  Tuple.Create(point, err) := GetByIndexWithProofFromChain(index, proofHash);
  if err <> nil then
  begin
    Result := TTuple.Create(nil, err);
    Exit;
  end;
  if point = nil then
  begin
    Result := TTuple.Create(nil, EProgrammerException.CreateFmt('period index[%d]proof[%s] Get fail', [index, proofHash.ToString]));
    Exit;
  end;
  err := Set(index, point);
  if err <> nil then
  begin
    FLog.Error('store period point by height Fail.', 'index', index, 'point', point.Json);
  end;

  Result := TTuple.Create(point, nil);
end;

function TPeriodLinkedArray.GetByIndexWithProofFromChain(index: UInt64; proofHash: THash): TTuple<TPoint, Error>;
var
  stime, etime: TDateTime;
  block: ISnapshotBlock;
  err: Error;
  blocks: TArray<ISnapshotBlock>;
  v: ISnapshotBlock;
  result: TElectionResult;
begin
  Tuple.Create(stime, etime) := FSnapshot.Index2Time(index);
  Tuple.Create(block, err) := FRw.GetSnapshotBlockByHash(proofHash);
  if err <> nil then
  begin
    Result := TTuple.Create(nil, err);
    Exit;
  end;
  if block = nil then
  begin
    Result := TTuple.Create(nil, EProgrammerException.CreateFmt('period index[%d] proof[%s] not exist.', [index, proofHash.ToString]));
    Exit;
  end;

  if block.Timestamp < stime then
  begin
    Result := TTuple.Create(TPoint.NewEmptyPoint(proofHash), nil);
    Exit;
  end;

  Tuple.Create(blocks, err) := FRw.GetSnapshotHeadersAfterOrEqualTime(THashHeight.Create(block.Hash, block.Height), @stime, nil);
  if err <> nil then
  begin
    Result := TTuple.Create(nil, err);
    Exit;
  end;

  for v in blocks do
    FLog.Debug(Format('[A]index:%d, height:%d, producer:%s, hash:%s', [index, v.Height, v.Producer.ToString, v.Hash.ToString]));

  if Length(blocks) = 0 then
  begin
    Result := TTuple.Create(TPoint.NewEmptyPoint(proofHash), nil);
    Exit;
  end;

  Tuple.Create(result, err) := FSnapshot.ElectionIndex(index);
  if err <> nil then
  begin
    Result := TTuple.Create(nil, err);
    Exit;
  end;
  for v in result.Plans do
    FLog.Debug(Format('[E]index:%d, producer:%s, stime:%s ', [index, v.Member.ToString, DateTimeToStr(v.STime)]));

  Result := GenPeriodPoint(index, @stime, @etime, proofHash, blocks, result);
end;

function TPeriodLinkedArray.GetByIndexWithProofFromDb(index: UInt64; proofHash: THash): TTuple<TPoint, Error>;
var
  value: TObject;
  ok: Boolean;
  proofEmptyResult: Boolean;
  err: Error;
  point: TPoint;
  stime, etime: TDateTime;
begin
  ok := FPeriods.Get(TValue.From(index), value);
  if not ok or (value = nil) then
  begin
    Tuple.Create(stime, etime) := Index2Time(index);
    Tuple.Create(proofEmptyResult, err) := FProof.ProofEmpty(stime, etime);
    if err <> nil then
    begin
      Result := TTuple.Create(nil, err);
      Exit;
    end;
    if proofEmptyResult then
    begin
      Result := TTuple.Create(TPoint.NewEmptyPoint(proofHash), nil);
      Exit;
    end;
  end
  else
  begin
    point := value as TPoint;
    if proofHash = point.Hash then
    begin
      Result := TTuple.Create(point, nil);
      Exit;
    end;
  end;
  Result := TTuple.Create(nil, nil);
end;

function TPeriodLinkedArray.Index2Time(i: UInt64): TTuple<TDateTime, TDateTime>;
begin
  Result := FTimeIndex.Index2Time(i);
end;

function TPeriodLinkedArray.Set(index: UInt64; block: TPoint): Error;
begin
  FPeriods.Add(TValue.From(index), block);
  Result := nil;
end;

function TPeriodLinkedArray.Time2Index(t: TDateTime): UInt64;
begin
  Result := FTimeIndex.Time2Index(t);
end;

function NewPeriodPointArray(rw: IChain; cs: IDposReader; proof: IRollbackProof; log: ILogger): ILinkedArray;
begin
  Result := TPeriodLinkedArray.Create(rw, cs, proof, log);
end;

end.