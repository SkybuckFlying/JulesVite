unit V.Ledger.Consensus.ChainRw;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Go.Big,
  Go.LevelDB,
  Go.Sync,
  V.Common.Types,
  V.Interfaces,
  V.Interfaces.Core,
  V.Ledger.Consensus.Cdb,
  V.Ledger.Consensus.Core.Group,
  V.Ledger.Consensus.Core.Vote,
  V.Ledger.Consensus.Core.Utils,
  V.Ledger.Consensus.LinkedArray,
  V.Ledger.Consensus.PeriodLinkedArray,
  V.Ledger.Consensus.RollbackProof,
  V.Ledger.Pool.Lock,
  V.LRU,
  V.Log15;

type
  IChain = V.Ledger.Chain.Interface.IChain;
  ISnapshotCs = V.Ledger.Consensus.Snapshot.ISnapshotCs; // Forward declaration

  TVoteDetails = record
    Vote: TVote;
    CurrentAddr: TAddress;
    RegisterList: TArray<TAddress>;
    Addr: TDictionary<TAddress, IBigInt>;
  end;

  TByBalanceVoteDetails = class(TComparer<TVoteDetails>)
  public
    function Compare(const Left, Right: TVoteDetails): Integer; override;
  end;

  IChainRw = interface
    ['{F1E2D3C4-B5A6-4A8B-9C8D-7E6F5A4B3C2D}']
    procedure Init(cs: ISnapshotCs);
    procedure Start;
    procedure Stop;
    function GetSnapshotBeforeTime(t: TDateTime): TTuple<ISnapshotBlock, Error>;
    function GetSeedsBeforeHashH(hash: THash): UInt64;
    function CalVotes(info: TGroupInfo; hashH: THashHeight): TTuple<TArray<PVote>, Error>;
    function CalVoteDetails(gid: TGid; info: TGroupInfo; block: THashHeight): TTuple<TArray<TVoteDetails>, Error>;
    function GetMemberInfo(gid: TGid): TTuple<TGroupInfo, Error>;
    function GetGid(block: IAccountBlock): TTuple<PGid, Error>;
    function GetLatestSnapshotBlock: ISnapshotBlock;
    function GetSuccessRateByHour(index: UInt64): TTuple<TDictionary<TAddress, Int32>, Error>;
    function GetSuccessRateByHour2(index: UInt64): TTuple<TDictionary<TAddress, TContent>, Error>;
    function GetSnapshotVoteCache(hash: THash): TTuple<TArray<TAddress>, Boolean>;
    procedure UpdateSnapshotVoteCache(hash: THash; addresses: TArray<TAddress>);
    function GetVoteLRUCache(gid: TGid; hash: THash): TTuple<TArray<TAddress>, Boolean>;
    procedure UpdateVoteLRUCache(gid: TGid; hash: THash; addrArr: TArray<TAddress>);
    procedure TriggerLoad(block: ISnapshotBlock);
  end;

  TChainRw = class(TInterfacedObject, IChainRw, IStateCh)
  private
    FGenesisTime: TDateTime;
    FRw: IChain;
    FRollbackLock: IChainRollback;
    FHourPoints: ILinkedArray;
    FDayPoints: ILinkedArray;
    FPeriodPoints: ILinkedArray;
    FDbCache: TConsensusDB;
    FLruCache: ILRUCache;
    FStarted: chan struct{};
    FSnapshotLoadCh: chan ISnapshotBlock;
    FWg: TWaitGroup;
    FLog: ILogger;
    FSnapshot: ISnapshotCs;
    function GenVoteDetails(snapshotHash: THash; registration: PRegistration; infos: TArray<PVoteInfo>; id: TTokenTypeId): TVoteDetails;
    function GenLruKey(gid: TGid; hash: THash): string;
  public
    constructor Create(rw: IChain; log: ILogger; rollbackLock: IChainRollback);
    { IChainRw }
    procedure Init(cs: ISnapshotCs);
    procedure Start;
    procedure Stop;
    function GetSnapshotBeforeTime(t: TDateTime): TTuple<ISnapshotBlock, Error>;
    function GetSeedsBeforeHashH(hash: THash): UInt64;
    function CalVotes(info: TGroupInfo; hashH: THashHeight): TTuple<TArray<PVote>, Error>;
    function CalVoteDetails(gid: TGid; info: TGroupInfo; block: THashHeight): TTuple<TArray<TVoteDetails>, Error>;
    function GetMemberInfo(gid: TGid): TTuple<TGroupInfo, Error>;
    function GetGid(block: IAccountBlock): TTuple<PGid, Error>;
    function GetLatestSnapshotBlock: ISnapshotBlock;
    function GetSuccessRateByHour(index: UInt64): TTuple<TDictionary<TAddress, Int32>, Error>;
    function GetSuccessRateByHour2(index: UInt64): TTuple<TDictionary<TAddress, TContent>, Error>;
    function GetSnapshotVoteCache(hash: THash): TTuple<TArray<TAddress>, Boolean>;
    procedure UpdateSnapshotVoteCache(hash: THash; addresses: TArray<TAddress>);
    function GetVoteLRUCache(gid: TGid; hash: THash): TTuple<TArray<TAddress>, Boolean>;
    procedure UpdateVoteLRUCache(gid: TGid; hash: THash; addrArr: TArray<TAddress>);
    procedure TriggerLoad(block: ISnapshotBlock);
    { IStateCh }
    function GetRegisterList(snapshotHash: THash; gid: TGid): TTuple<TArray<PRegistration>, Error>;
    function GetVoteList(snapshotHash: THash; gid: TGid): TTuple<TArray<PVoteInfo>, Error>;
    function GetConfirmedBalanceList(addrList: TArray<TAddress>; tokenId: TTokenTypeId; sbHash: THash): TTuple<TDictionary<TAddress, IBigInt>, Error>;
    function GetSnapshotBlockByHeight(height: UInt64): TTuple<ISnapshotBlock, Error>;
  end;

function NewChainRw(rw: IChain; log: ILogger; rollbackLock: IChainRollback): IChainRw;

const
  Period = 1;
  Hour = 48 * Period;
  Day = 24 * Hour;

implementation

uses
  System.DateUtils,
  System.Threading,
  Go.Context,
  V.Ledger.Consensus.Snapshot;

{ TByBalanceVoteDetails }

function TByBalanceVoteDetails.Compare(const Left, Right: TVoteDetails): Integer;
var
  r: Integer;
begin
  r := Right.Vote.Balance.Cmp(Left.Vote.Balance);
  if r = 0 then
    Result := AnsiString.Compare(Left.Vote.Name, Right.Vote.Name)
  else
    Result := r;
end;

{ TChainRw }

constructor TChainRw.Create(rw: IChain; log: ILogger; rollbackLock: IChainRollback);
var
  db: ILevelDB;
  err: Error;
  cache: ILRUCache;
begin
  FRw := rw;
  FLog := log;
  FRollbackLock := rollbackLock;
  FGenesisTime := FRw.GetGenesisSnapshotBlock.Timestamp;
  Tuple.Create(db, err) := FRw.NewDb('consensus');
  if err <> nil then
    raise EProgrammerException.Create(err.Error);
  FDbCache := NewConsensusDB(db);
  Tuple.Create(cache, err) := NewLRU(1024 * 10);
  if err <> nil then
    raise EProgrammerException.Create(err.Error);
  FLruCache := cache;
end;

procedure TChainRw.Init(cs: ISnapshotCs);
var
  proof: IRollbackProof;
begin
  if cs = nil then
    raise EProgrammerException.Create('snapshot cs is nil.');
  proof := NewRollbackProof(FRw);
  FPeriodPoints := NewPeriodPointArray(FRw, cs, proof, FLog);
  FHourPoints := NewHourLinkedArray(FPeriodPoints, FDbCache, proof, TTimeSpan.FromSeconds(cs.GetInfo.PlanInterval), FGenesisTime, FLog);
  FDayPoints := NewDayLinkedArray(FHourPoints, FDbCache, proof, cs.DayVoteStat, FGenesisTime, FLog);
  FSnapshot := cs;
  FSnapshotLoadCh := make(chan ISnapshotBlock);
end;

procedure TChainRw.Start;
var
  ctx: IContext;
  cancel: TCancelFunc;
begin
  FStarted := make(chan struct{});
  Tuple.Create(ctx, cancel) := TContext.WithCancel(TContext.Background);
  TGo.Create(
    procedure
    var
      ticker: ITicker;
      block: ISnapshotBlock;
      t: TDateTime;
      index, lastIdx: UInt64;
      point: TPoint;
      err: Error;
      b: ISnapshotBlock;
    begin
      FWg.Add(1);
      try
        ticker := TTime.NewTicker(30 * TTime.Second);
        try
          while True do
          begin
            select
            case ticker.C:
              block := GetLatestSnapshotBlock;
              t := block.Timestamp;
              index := FDayPoints.Time2Index(t);
              Tuple.Create(point, err) := FDayPoints.GetByIndex(index);
              if err <> nil then
                FLog.Error('can''t get day info by index', 'index', index, 'time', t)
              else
                FLog.Info('get day by info index', 'index', index, 'time', t, 'point', point.Json);

              if index > 0 then
              begin
                lastIdx := index - 1;
                Tuple.Create(point, err) := FDayPoints.GetByIndex(lastIdx);
                if err <> nil then
                  FLog.Error('can''t get day info by last index', 'index', lastIdx, 'time', t)
                else
                  FLog.Info('get day by info last index', 'index', lastIdx, 'time', t, 'point', point.Json);
              end;
            case b := <-FSnapshotLoadCh:
              FSnapshot.LoadVotes(b);
            case <-FStarted:
              cancel();
              Exit;
            case <-ctx.Done:
              Exit;
            end;
          end;
        finally
          ticker.Stop;
        end;
      finally
        FWg.Done;
      end;
    end
  );
end;

procedure TChainRw.Stop;
begin
  close(FStarted);
  FWg.Wait;
end;

procedure TChainRw.TriggerLoad(block: ISnapshotBlock);
begin
  select
  case FSnapshotLoadCh <- block:
  default:
  end;
end;

procedure TChainRw.UpdateSnapshotVoteCache(hash: THash; addresses: TArray<TAddress>);
begin
  FDbCache.StoreElectionResultByHash(hash, addresses);
end;

procedure TChainRw.UpdateVoteLRUCache(gid: TGid; hash: THash; addrArr: TArray<TAddress>);
begin
  if FLruCache <> nil then
  begin
    FLog.Info(Format('store election result %s, %+v', [hash.ToString, addrArr]));
    FLruCache.Add(GenLruKey(gid, hash), addrArr);
  end;
end;

function TChainRw.CalVoteDetails(gid: TGid; info: TGroupInfo; block: THashHeight): TTuple<TArray<TVoteDetails>, Error>;
var
  registerList: TArray<PRegistration>;
  err: Error;
  votes: TArray<PVoteInfo>;
  registers: TArray<TVoteDetails>;
  v: PRegistration;
begin
  Tuple.Create(registerList, err) := FRw.GetRegisterList(block.Hash, gid);
  if err <> nil then
    Exit(TTuple.Create(nil, err));
  Tuple.Create(votes, err) := FRw.GetVoteList(block.Hash, gid);
  if err <> nil then
    Exit(TTuple.Create(nil, err));

  SetLength(registers, 0);
  for v in registerList do
    registers := registers + [GenVoteDetails(block.Hash, v, votes, info.ConsensusGroupInfo.CountingTokenId)];

  TArray.Sort<TVoteDetails>(registers, TByBalanceVoteDetails.Create);
  Result := TTuple.Create(registers, nil);
end;

function TChainRw.CalVotes(info: TGroupInfo; hashH: THashHeight): TTuple<TArray<PVote>, Error>;
begin
  Result := CalVotes(info.ConsensusGroupInfo, hashH.Hash, Self);
end;

function TChainRw.GenLruKey(gid: TGid; hash: THash): string;
begin
  Result := gid.ToString + hash.ToString;
end;

function TChainRw.GenVoteDetails(snapshotHash: THash; registration: PRegistration; infos: TArray<PVoteInfo>; id: TTokenTypeId): TVoteDetails;
var
  addrs: TArray<TAddress>;
  v: PVoteInfo;
  balanceMap: TDictionary<TAddress, IBigInt>;
  err: Error;
  balanceTotal, val: IBigInt;
begin
  SetLength(addrs, 0);
  for v in infos do
  begin
    if v.SbpName = registration.Name then
      addrs := addrs + [v.VoteAddr];
  end;
  Tuple.Create(balanceMap, err) := FRw.GetConfirmedBalanceList(addrs, id, snapshotHash);
  balanceTotal := TBigInt.New;
  if balanceMap <> nil then
  begin
    for val in balanceMap.Values do
      balanceTotal.Add(balanceTotal, val);
  end;
  Result.Vote.Name := registration.Name;
  Result.Vote.Addr := registration.BlockProducingAddress;
  Result.Vote.Balance := balanceTotal;
  Result.CurrentAddr := registration.BlockProducingAddress;
  Result.RegisterList := registration.HisAddrList;
  Result.Addr := balanceMap;
end;

function TChainRw.GetConfirmedBalanceList(addrList: TArray<TAddress>; tokenId: TTokenTypeId; sbHash: THash): TTuple<TDictionary<TAddress, IBigInt>, Error>;
begin
  Result := FRw.GetConfirmedBalanceList(addrList, tokenId, sbHash);
end;

function TChainRw.GetGid(block: IAccountBlock): TTuple<PGid, Error>;
var
  meta: PContractMeta;
  err: Error;
begin
  Tuple.Create(meta, err) := FRw.GetContractMeta(block.AccountAddress);
  if err <> nil then
  begin
    Result := TTuple.Create(nil, err);
    Exit;
  end;
  Result := TTuple.Create(@meta.Gid, nil);
end;

function TChainRw.GetLatestSnapshotBlock: ISnapshotBlock;
begin
  Result := FRw.GetLatestSnapshotBlock;
end;

function TChainRw.GetMemberInfo(gid: TGid): TTuple<TGroupInfo, Error>;
var
  result: TGroupInfo;
  head: ISnapshotBlock;
  consensusGroupList: TArray<PConsensusGroupInfo>;
  err: Error;
  v: PConsensusGroupInfo;
begin
  result := nil;
  head := FRw.GetLatestSnapshotBlock;
  Tuple.Create(consensusGroupList, err) := FRw.GetConsensusGroupList(head.Hash);
  if err <> nil then
  begin
    Result := TTuple.Create(nil, err);
    Exit;
  end;
  for v in consensusGroupList do
  begin
    if v.Gid = gid then
      result := NewGroupInfo(FGenesisTime, v^);
  end;
  if result = nil then
  begin
    Result := TTuple.Create(nil, EProgrammerException.CreateFmt('can''t get consensus group[%s] info by [%s-%d].', [gid.ToString, head.Hash.ToString, head.Height]));
    Exit;
  end;
  Result := TTuple.Create(result, nil);
end;

function TChainRw.GetRegisterList(snapshotHash: THash; gid: TGid): TTuple<TArray<PRegistration>, Error>;
begin
  Result := FRw.GetRegisterList(snapshotHash, gid);
end;

function TChainRw.GetSeedsBeforeHashH(hash: THash): UInt64;
begin
  Result := FRw.GetRandomSeed(hash, 25);
end;

function TChainRw.GetSnapshotBeforeTime(t: TDateTime): TTuple<ISnapshotBlock, Error>;
var
  block: ISnapshotBlock;
  e: Error;
begin
  Tuple.Create(block, e) := FRw.GetSnapshotHeaderBeforeTime(t);
  if e <> nil then
  begin
    Result := TTuple.Create(nil, e);
    Exit;
  end;
  if block = nil then
  begin
    Result := TTuple.Create(nil, EProgrammerException.CreateFmt('before time[%s] block not exist', [DateTimeToStr(t)]));
    Exit;
  end;
  Result := TTuple.Create(block, nil);
end;

function TChainRw.GetSnapshotBlockByHeight(height: UInt64): TTuple<ISnapshotBlock, Error>;
begin
  Result := FRw.GetSnapshotBlockByHeight(height);
end;

function TChainRw.GetSnapshotVoteCache(hash: THash): TTuple<TArray<TAddress>, Boolean>;
var
  resultArr: TArray<TAddress>;
  b: Boolean;
begin
  Tuple.Create(resultArr, b) := FDbCache.GetElectionResultByHash(hash);
  if b then
    Exit(TTuple.Create(resultArr, True));

  Tuple.Create(resultArr, b) := GetVoteLRUCache(GID_Snapshot, hash);
  if b then
  begin
    UpdateSnapshotVoteCache(hash, resultArr);
    Exit(TTuple.Create(resultArr, True));
  end;
  Result := TTuple.Create(nil, False);
end;

function TChainRw.GetSuccessRateByHour(index: UInt64): TTuple<TDictionary<TAddress, Int32>, Error>;
var
  result: TDictionary<TAddress, Int32>;
  hourInfos: TDictionary<TAddress, TContent>;
  prevHash: PHash;
  i: UInt64;
  p: TPoint;
  err: Error;
  tmpIndex: UInt64;
  infos: TDictionary<TAddress, TContent>;
  k: TAddress;
  v: TContent;
  c: TContent;
  ok: Boolean;
begin
  result := TDictionary<TAddress, Int32>.Create;
  hourInfos := TDictionary<TAddress, TContent>.Create;
  prevHash := nil;
  i := 0;
  while i < Hour do
  begin
    if i > index then
      Break;
    tmpIndex := index - i;
    if prevHash = nil then
      Tuple.Create(p, err) := FPeriodPoints.GetByIndex(tmpIndex)
    else
      Tuple.Create(p, err) := FPeriodPoints.GetByIndexWithProof(tmpIndex, prevHash^);
    if err <> nil then
      Exit(TTuple.Create(nil, err));
    if p = nil then
      Break;

    infos := p.Sbps;
    for k, v in infos do
    begin
      if not hourInfos.TryGetValue(k, c) then
        hourInfos.Add(k, v.Copy)
      else
        c.Merge(v);
    end;
    prevHash := @p.PrevHash;
    Inc(i);
  end;

  for k, v in hourInfos do
    result.Add(k, v.Rate);
  Result := TTuple.Create(result, nil);
end;

function TChainRw.GetSuccessRateByHour2(index: UInt64): TTuple<TDictionary<TAddress, TContent>, Error>;
var
  hourInfos: TDictionary<TAddress, TContent>;
  i: UInt64;
  tmpIndex: UInt64;
  p: TPoint;
  err: Error;
  infos: TDictionary<TAddress, TContent>;
  k: TAddress;
  v: TContent;
  c: TContent;
begin
  hourInfos := TDictionary<TAddress, TContent>.Create;
  i := 0;
  while i < Hour do
  begin
    if i > index then
      Break;
    tmpIndex := index - i;
    Tuple.Create(p, err) := FPeriodPoints.GetByIndex(tmpIndex);
    if err <> nil then
      Exit(TTuple.Create(nil, err));

    infos := p.Sbps;
    for k, v in infos do
    begin
      if not hourInfos.TryGetValue(k, c) then
        hourInfos.Add(k, v.Copy)
      else
        c.Merge(v);
    end;
    Inc(i);
  end;
  Result := TTuple.Create(hourInfos, nil);
end;

function TChainRw.GetVoteList(snapshotHash: THash; gid: TGid): TTuple<TArray<PVoteInfo>, Error>;
begin
  Result := FRw.GetVoteList(snapshotHash, gid);
end;

function TChainRw.GetVoteLRUCache(gid: TGid; hash: THash): TTuple<TArray<TAddress>, Boolean>;
var
  value: TObject;
  ok: Boolean;
begin
  if FLruCache = nil then
    Exit(TTuple.Create(nil, False));

  Tuple.Create(value, ok) := FLruCache.Get(GenLruKey(gid, hash));
  if ok then
    Result := TTuple.Create(value as TArray<TAddress>, ok)
  else
    Result := TTuple.Create(nil, ok);
end;

function NewChainRw(rw: IChain; log: ILogger; rollbackLock: IChainRollback): IChainRw;
begin
  Result := TChainRw.Create(rw, log, rollbackLock);
end;

end.