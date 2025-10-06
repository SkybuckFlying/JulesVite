unit V.Ledger.Consensus;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Go.Context,
  Go.Sync,
  V.Common,
  V.Common.Types,
  V.Interfaces,
  V.Interfaces.Core,
  V.Ledger.Consensus.Cdb,
  V.Ledger.Consensus.Core.Group,
  V.Ledger.Pool.Lock,
  V.Log15,
  V.Ledger.Consensus.Event,
  V.Ledger.Consensus.Result,
  V.Ledger.Consensus.ChainRw,
  V.Ledger.Consensus.Snapshot,
  V.Ledger.Consensus.ConsensusContract,
  V.Ledger.Consensus.DposReader,
  V.Ledger.Consensus.Api,
  V.Ledger.Consensus.SubscribeTrigger,
  V.Ledger.Consensus.Trigger,
  V.Ledger.Consensus.Config,
  V.Ledger.Consensus.Dpos,
  V.Ledger.Consensus.Subscriber,
  V.Ledger.Consensus.Core;

type
  IConsensusReader = interface
    ['{C5B7F8D3-8D4C-4D4B-8B4A-7A5D8D3C4B8B}']
    function ReadByIndex(gid: TGid; index: UInt64): TTuple<TArray<PConsensusEvent>, UInt64, Error>;
    function VoteTimeToIndex(gid: TGid; t2: TDateTime): TTuple<UInt64, Error>;
    function VoteIndexToTime(gid: TGid; i: UInt64): TTuple<PDateTime, PDateTime, Error>;
  end;

  IAPIConsensusReader = interface
    ['{A4B7F8D3-8D4C-4D4B-8B4A-7A5D8D3C4B8B}']
    function ReadVoteMap(t: TDateTime): TTuple<TArray<TVoteDetails>, PHashHeight, Error>;
    function ReadSuccessRate(start, &end: UInt64): TTuple<TArray<TDictionary<TAddress, TContent>>, Error>;
    function ReadByIndex(gid: TGid; index: UInt64): TTuple<TArray<PConsensusEvent>, UInt64, Error>;
  end;

  IConsensusLife = interface
    ['{B3C7F8D3-8D4C-4D4B-8B4A-7A5D8D3C4B8B}']
    procedure Start;
    function Init(cfg: PConsensusCfg): Error;
    procedure Stop;
  end;

  IConsensus = interface(IConsensusVerifier, ISubscribeTrigger, IConsensusReader, IConsensusLife)
    ['{D2A7F8D3-8D4C-4D4B-8B4A-7A5D8D3C4B8B}']
    function API: IAPIConsensusReader;
    function SBPReader: ISBPStatReader;
  end;

  TConsensus = class(TInterfacedObject, IConsensus)
  private
    FConsensusCfg: PConsensusCfg;
    FSubscriber: ISubscribeTrigger;
    FSubscribeTrigger: ISubscribeTrigger;
    FLifecycleStatus: TLifecycleStatus;
    FMLog: ILogger;
    FGenesis: TDateTime;
    FRw: IChainRw;
    FRollback: IChainRollback;
    FSnapshot: ISnapshotCs;
    FContracts: TContractsCs;
    FDposWrapper: TDposReader;
    FApi: IAPIConsensusReader;
    FWg: TWaitGroup;
    FClosed: TChan;
    FCtx: IContext;
    FCancelFn: TCancelFunc;
    FTg: TTrigger;
  public
    constructor Create(ch: IChain; rollback: IChainRollback);
    function SBPReader: ISBPStatReader;
    function API: IAPIConsensusReader;
    { IConsensusVerifier }
    function VerifySnapshotProducer(header: ISnapshotBlock): TTuple<Boolean, Error>;
    function VerifyABsProducer(abs: TDictionary<TGid, TArray<IAccountBlock>>): TTuple<TArray<IAccountBlock>, Error>;
    function VerifyAccountProducer(accountBlock: IAccountBlock): TTuple<Boolean, Error>;
    { ISubscribeTrigger }
    procedure Subscribe(gid: TGid; id: string; addr: PAddress; fn: TConsensusEventFunc);
    procedure UnSubscribe(gid: TGid; id: string);
    procedure SubscribeProducers(gid: TGid; id: string; fn: TProducersEventFunc);
    procedure TriggerMineEvent(addr: TAddress): Error;
    { IConsensusReader }
    function ReadByIndex(gid: TGid; index: UInt64): TTuple<TArray<PConsensusEvent>, UInt64, Error>;
    function VoteTimeToIndex(gid: TGid; t2: TDateTime): TTuple<UInt64, Error>;
    function VoteIndexToTime(gid: TGid; i: UInt64): TTuple<PDateTime, PDateTime, Error>;
    { IConsensusLife }
    procedure Start;
    function Init(cfg: PConsensusCfg): Error;
    procedure Stop;
  end;

function NewConsensus(ch: IChain; rollback: IChainRollback): IConsensus;

implementation

uses
  V.Ledger.Consensus.ConsensusContractDpos;

{ TConsensus }

constructor TConsensus.Create(ch: IChain; rollback: IChainRollback);
var
  log: ILogger;
  rw: IChainRw;
  sub: ISubscribeTrigger;
  apiSnapshot: TAPISnapshot;
begin
  log := TLog15.New('module', 'consensus');
  rw := NewChainRw(ch, log, rollback);

  sub := NewConsensusSubscriber;
  FRw := rw;
  FRollback := rollback;
  FMLog := log;
  FSubscriber := sub;
  FSubscribeTrigger := sub;
  FSnapshot := NewSnapshotCs(FRw, FMLog);
  FContracts := TContractsCs.Create(FRw, FMLog);
  FDposWrapper := TDposReader.Create(FSnapshot, FContracts, FMLog);
  FApi := NewAPISnapshot(FSnapshot);
  FWg := TWaitGroup.Create;
end;

function TConsensus.API: IAPIConsensusReader;
begin
  Result := FApi;
end;

function TConsensus.Init(cfg: PConsensusCfg): Error;
var
  err: Error;
begin
  if not FLifecycleStatus.PreInit then
    raise EProgrammerException.Create('pre init fail.');
  try
    if cfg = nil then
      cfg := DefaultCfg;
    FConsensusCfg := cfg;

    FRw.Init(FSnapshot);

    FTg := NewTrigger(FRollback);
    err := FContracts.LoadGid(GID_DPoS);
    if err <> nil then
      raise EProgrammerException.Create(err.Error);
    Result := nil;
  finally
    FLifecycleStatus.PostInit;
  end;
end;

function TConsensus.ReadByIndex(gid: TGid; index: UInt64): TTuple<TArray<PConsensusEvent>, UInt64, Error>;
var
  reader: IDposReader;
  err: Error;
  eResult: TElectionResult;
  voteTime: TDateTime;
  result: TArray<PConsensusEvent>;
  p: TMemberPlan;
  e: TConsensusEvent;
begin
  Tuple.Create(reader, err) := FDposWrapper.GetDposConsensus(gid);
  if err <> nil then
  begin
    Result := TTuple.Create(nil, 0, err);
    Exit;
  end;

  Tuple.Create(eResult, err) := reader.ElectionIndex(index);
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

function TConsensus.SBPReader: ISBPStatReader;
begin
  Result := FSnapshot;
end;

procedure TConsensus.Start;
var
  reader: IDposReader;
  err: Error;
begin
  FLifecycleStatus.PreStart;
  try
    make(FClosed);
    Tuple.Create(FCtx, FCancelFn) := TContext.WithCancel(TContext.Background);

    TGo.Create(
      procedure
      begin
        FWg.Add(1);
        try
          FTg.Update(FCtx, GID_Snapshot, FSnapshot, FSubscribeTrigger);
        finally
          FWg.Done;
        end;
      end
    );

    Tuple.Create(reader, err) := FDposWrapper.GetDposConsensus(GID_DPoS);
    if err <> nil then
      raise EProgrammerException.Create(err.Error);

    TGo.Create(
      procedure
      begin
        FWg.Add(1);
        try
          FTg.Update(FCtx, GID_DPoS, reader, FSubscribeTrigger);
        finally
          FWg.Done;
        end;
      end
    );

    FRw.Start;
  finally
    FLifecycleStatus.PostStart;
  end;
end;

procedure TConsensus.Stop;
begin
  FLifecycleStatus.PreStop;
  try
    FRw.Stop;
    FCancelFn();
    close(FClosed);
    FWg.Wait;
  finally
    FLifecycleStatus.PostStop;
  end;
end;

procedure TConsensus.Subscribe(gid: TGid; id: string; addr: PAddress; fn: TConsensusEventFunc);
begin
  FSubscriber.Subscribe(gid, id, addr, fn);
end;

procedure TConsensus.SubscribeProducers(gid: TGid; id: string; fn: TProducersEventFunc);
begin
  FSubscriber.SubscribeProducers(gid, id, fn);
end;

procedure TConsensus.TriggerMineEvent(addr: TAddress): Error;
begin
  Result := FSubscribeTrigger.TriggerMineEvent(addr);
end;

procedure TConsensus.UnSubscribe(gid: TGid; id: string);
begin
  FSubscriber.UnSubscribe(gid, id);
end;

function TConsensus.VerifyABsProducer(abs: TDictionary<TGid, TArray<IAccountBlock>>): TTuple<TArray<IAccountBlock>, Error>;
var
  result: TArray<IAccountBlock>;
  pair: TPair<TGid, TArray<IAccountBlock>>;
  blocks: TArray<IAccountBlock>;
  err: Error;
  tel: TContractDposCs;
begin
  SetLength(result, 0);
  for pair in abs do
  begin
    // Inlined logic from the removed VerifyABsProducerByGid
    Tuple.Create(tel, err) := FContracts.GetOrLoadGid(pair.Key);
    if err <> nil then
      Exit(TTuple.Create(nil, err));
    if tel = nil then
      Exit(TTuple.Create(nil, EProgrammerException.Create('consensus group not exist')));

    Tuple.Create(blocks, err) := tel.VerifyAccountsProducer(pair.Value);
    if err <> nil then
      Exit(TTuple.Create(nil, err));

    result := result + blocks;
  end;
  Result := TTuple.Create(result, nil);
end;

function TConsensus.VerifyAccountProducer(accountBlock: IAccountBlock): TTuple<Boolean, Error>;
var
  gid: PGid;
  err: Error;
  tel: TContractDposCs;
begin
  Tuple.Create(gid, err) := FRw.GetGid(accountBlock);
  if err <> nil then
  begin
    Result := TTuple.Create(False, err);
    Exit;
  end;
  Tuple.Create(tel, err) := FContracts.GetOrLoadGid(gid^);
  if err <> nil then
  begin
    Result := TTuple.Create(False, err);
    Exit;
  end;
  if tel = nil then
  begin
    Result := TTuple.Create(False, EProgrammerException.Create('consensus group not exist'));
    Exit;
  end;
  Result := tel.VerifyAccountProducer(accountBlock);
end;

function TConsensus.VerifySnapshotProducer(header: ISnapshotBlock): TTuple<Boolean, Error>;
begin
  Result := FSnapshot.VerifyProducerAndSeed(header);
end;

function TConsensus.VoteIndexToTime(gid: TGid; i: UInt64): TTuple<PDateTime, PDateTime, Error>;
var
  reader: IDposReader;
  err: Error;
  st, et: TDateTime;
begin
  Tuple.Create(reader, err) := FDposWrapper.GetDposConsensus(gid);
  if err <> nil then
  begin
    Result := TTuple.Create(nil, nil, EProgrammerException.CreateFmt('consensus group[%s] not exist', [gid.ToString]));
    Exit;
  end;
  Tuple.Create(st, et) := reader.Index2Time(i);
  Result := TTuple.Create(@st, @et, nil);
end;

function TConsensus.VoteTimeToIndex(gid: TGid; t2: TDateTime): TTuple<UInt64, Error>;
var
  reader: IDposReader;
  err: Error;
begin
  Tuple.Create(reader, err) := FDposWrapper.GetDposConsensus(gid);
  if err <> nil then
  begin
    Result := TTuple.Create(0, err);
    Exit;
  end;
  Result := TTuple.Create(reader.Time2Index(t2), nil);
end;

function NewConsensus(ch: IChain; rollback: IChainRollback): IConsensus;
begin
  Result := TConsensus.Create(ch, rollback);
end;

end.