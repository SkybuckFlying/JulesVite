unit V.Ledger.Consensus.LinkedArray;

interface

uses
  System.SysUtils,
  V.Common.Types,
  V.Ledger.Consensus.Core.TimeIndexer,
  V.Ledger.Consensus.Cdb,
  V.Ledger.Consensus.RollbackProof,
  V.Log15;

type
  TExtraDataFn = reference to function(b: Byte; u: UInt64; hash: THash): TTuple<TVoteContent, Error>;

  ILinkedArray = interface(ITimeIndex)
    ['{C5B7F8D3-8D4C-4D4B-8B4A-7A5D8D3C4B8C}']
    function GetByIndex(index: UInt64): TTuple<TPoint, Error>;
    function GetByIndexWithProof(index: UInt64; proofHash: THash): TTuple<TPoint, Error>;
  end;

  TLinkedArray = class(TInterfacedObject, ILinkedArray)
  private
    FTimeIndex: ITimeIndex;
    FPrefix: Byte;
    FRate: UInt64;
    FDb: TConsensusDB;
    FLowerArr: ILinkedArray;
    FProof: IRollbackProof;
    FExtraDataFn: TExtraDataFn;
    FLog: ILogger;
    function GetByIndexWithProofFromDb(index: UInt64; proofHash: THash): TTuple<TPoint, Boolean, Error>;
    function GetByIndexWithProofFromKernel(index: UInt64; proofHash: THash): TTuple<TPoint, Error>;
  public
    constructor Create;
    { ITimeIndex }
    function Time2Index(t: TDateTime): UInt64;
    function Index2Time(i: UInt64): TTuple<TDateTime, TDateTime>;
    { ILinkedArray }
    function GetByIndex(index: UInt64): TTuple<TPoint, Error>;
    function GetByIndexWithProof(index: UInt64; proofHash: THash): TTuple<TPoint, Error>;
  end;

function NewDayLinkedArray(hour: ILinkedArray; db: TConsensusDB; proof: IRollbackProof; fn: TExtraDataFn; genesisTime: TDateTime; log: ILogger): ILinkedArray;
function NewHourLinkedArray(period: ILinkedArray; db: TConsensusDB; proof: IRollbackProof; intervalSec: TTimeSpan; genesisTime: TDateTime; log: ILogger): ILinkedArray;

implementation

uses
  System.DateUtils,
  System.JSON;

{ TLinkedArray }

constructor TLinkedArray.Create;
begin
  //
end;

function TLinkedArray.GetByIndex(index: UInt64): TTuple<TPoint, Error>;
var
  etime: TDateTime;
  hash: THash;
  err: Error;
begin
  etime := Index2Time(index).Item2;
  Tuple.Create(hash, err) := FProof.ProofHash(etime);
  if err <> nil then
  begin
    Result := TTuple.Create(nil, err);
    Exit;
  end;
  Result := GetByIndexWithProof(index, hash);
end;

function TLinkedArray.GetByIndexWithProof(index: UInt64; proofHash: THash): TTuple<TPoint, Error>;
var
  point: TPoint;
  exists: Boolean;
  err: Error;
begin
  Tuple.Create(point, exists, err) := GetByIndexWithProofFromDb(index, proofHash);
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

  Tuple.Create(point, err) := GetByIndexWithProofFromKernel(index, proofHash);
  if err <> nil then
  begin
    Result := TTuple.Create(nil, err);
    Exit;
  end;
  if point = nil then
  begin
    Result := TTuple.Create(nil, EProgrammerException.CreateFmt('index[%d][%d]proof[%s] Get fail', [FPrefix, index, proofHash.ToString]));
    Exit;
  end;

  if exists and point.IsEmpty then
    FDb.DeletePointByHeight(FPrefix, index)
  else
  begin
    err := FDb.StorePointByHeight(FPrefix, index, point);
    if err <> nil then
    begin
      FLog.Error('store point by height Fail.', 'index', index, 'point', point.Json);
    end;
  end;
  Result := TTuple.Create(point, nil);
end;

function TLinkedArray.GetByIndexWithProofFromDb(index: UInt64; proofHash: THash): TTuple<TPoint, Boolean, Error>;
var
  exists: Boolean;
  point: TPoint;
  err: Error;
  emptyProofResult: Boolean;
  stime, etime: TDateTime;
begin
  exists := False;
  Tuple.Create(point, err) := FDb.GetPointByHeight(FPrefix, index);
  if err <> nil then
  begin
    Result := TTuple.Create(nil, exists, err);
    Exit;
  end;

  if point = nil then
  begin
    Tuple.Create(stime, etime) := Index2Time(index);
    Tuple.Create(emptyProofResult, err) := FProof.ProofEmpty(stime, etime);
    if err <> nil then
    begin
      Result := TTuple.Create(nil, exists, err);
      Exit;
    end;
    if emptyProofResult then
    begin
      Result := TTuple.Create(TPoint.NewEmptyPoint(proofHash), exists, nil);
      Exit;
    end;
  end
  else
  begin
    exists := True;
    if proofHash = point.Hash then
    begin
      Result := TTuple.Create(point, exists, nil);
      Exit;
    end;
  end;
  Result := TTuple.Create(nil, exists, nil);
end;

function TLinkedArray.GetByIndexWithProofFromKernel(index: UInt64; proofHash: THash): TTuple<TPoint, Error>;
var
  result: TPoint;
  start, &end, i: UInt64;
  tmpProofHash: THash;
  p: TPoint;
  err: Error;
  voteContent: TVoteContent;
begin
  result := TPoint.NewEmptyPoint(proofHash);
  start := index * FRate;
  &end := start + FRate;
  tmpProofHash := proofHash;
  i := &end;
  while i > start do
  begin
    Tuple.Create(p, err) := FLowerArr.GetByIndexWithProof(i - 1, tmpProofHash);
    if err <> nil then
    begin
      Result := TTuple.Create(nil, err);
      Exit;
    end;
    if p.IsEmpty then
    begin
      Dec(i);
      Continue;
    end;
    tmpProofHash := p.PrevHash;
    err := result.LeftAppend(p);
    if err <> nil then
    begin
      Result := TTuple.Create(nil, err);
      Exit;
    end;
    Dec(i);
  end;

  if not result.IsEmpty and Assigned(FExtraDataFn) then
  begin
    Tuple.Create(voteContent, err) := FExtraDataFn(FPrefix, index, proofHash);
    if err <> nil then
    begin
      Result := TTuple.Create(nil, err);
      Exit;
    end;
    if voteContent <> nil then
      result.Votes := voteContent;
  end;
  Result := TTuple.Create(result, nil);
end;

function TLinkedArray.Index2Time(i: UInt64): TTuple<TDateTime, TDateTime>;
begin
  Result := FTimeIndex.Index2Time(i);
end;

function TLinkedArray.Time2Index(t: TDateTime): UInt64;
begin
  Result := FTimeIndex.Time2Index(t);
end;

function NewDayLinkedArray(hour: ILinkedArray; db: TConsensusDB; proof: IRollbackProof; fn: TExtraDataFn; genesisTime: TDateTime; log: ILogger): ILinkedArray;
var
  dayArr: TLinkedArray;
begin
  dayArr := TLinkedArray.Create;
  dayArr.FRate := 24; // 24 hour in day
  dayArr.FPrefix := IndexPointDay;
  dayArr.FLowerArr := hour;
  dayArr.FDb := db;
  dayArr.FProof := proof;
  dayArr.FExtraDataFn := fn;
  dayArr.FTimeIndex := NewTimeIndex(genesisTime, OneDay);
  dayArr.FLog := log;
  Result := dayArr;
end;

function NewHourLinkedArray(period: ILinkedArray; db: TConsensusDB; proof: IRollbackProof; intervalSec: TTimeSpan; genesisTime: TDateTime; log: ILogger): ILinkedArray;
var
  hourArr: TLinkedArray;
begin
  hourArr := TLinkedArray.Create;
  hourArr.FRate := Trunc(OneHour / intervalSec);
  hourArr.FPrefix := IndexPointHour;
  hourArr.FLowerArr := period;
  hourArr.FDb := db;
  hourArr.FProof := proof;
  hourArr.FTimeIndex := NewTimeIndex(genesisTime, OneHour);
  hourArr.FLog := log;
  Result := hourArr;
end;

end.