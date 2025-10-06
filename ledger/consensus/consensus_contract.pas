unit V.Ledger.Consensus.ConsensusContract;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Go.Sync,
  V.Common.Types,
  V.Ledger.Consensus.ChainRw,
  V.Log15,
  V.Ledger.Consensus.ConsensusContractDpos,
  V.Ledger.Consensus.Result,
  V.Ledger.Consensus.Core.Group;

type
  TContractsCs = class
  private
    FRw: IChainRw;
    FContracts: TDictionary<TGid, TContractDposCs>;
    FContractsMu: TMutex;
    FLog: ILogger;
    function GetForGid(gid: TGid): TContractDposCs;
    function ReloadGid(gid: TGid): TTuple<TContractDposCs, Error>;
  public
    constructor Create(rw: IChainRw; log: ILogger);
    destructor Destroy; override;
    function GetOrLoadGid(gid: TGid): TTuple<TContractDposCs, Error>;
    function LoadGid(gid: TGid): Error;
    function ElectionTime(gid: TGid; t: TDateTime): TTuple<TElectionResult, Error>;
    function ElectionIndex(gid: TGid; index: UInt64): TTuple<TElectionResult, Error>;
  end;

implementation

uses
  System.Classes;

{ TContractsCs }

constructor TContractsCs.Create(rw: IChainRw; log: ILogger);
begin
  FRw := rw;
  FLog := log.New('gid', 'contracts');
  FContracts := TDictionary<TGid, TContractDposCs>.Create;
  FContractsMu := TMutex.Create;
end;

destructor TContractsCs.Destroy;
begin
  FContracts.Free;
  FContractsMu.Free;
  inherited;
end;

function TContractsCs.ElectionIndex(gid: TGid; index: UInt64): TTuple<TElectionResult, Error>;
var
  result: TContractDposCs;
  err: Error;
begin
  Tuple.Create(result, err) := GetOrLoadGid(gid);
  if err <> nil then
  begin
    Result := TTuple.Create(Default(TElectionResult), err);
    Exit;
  end;
  if result = nil then
  begin
    Result := TTuple.Create(Default(TElectionResult), EProgrammerException.CreateFmt('can''t load contract group for gid:%s, index:%d', [gid.ToString, index]));
    Exit;
  end;
  Result := result.ElectionIndex(index);
end;

function TContractsCs.ElectionTime(gid: TGid; t: TDateTime): TTuple<TElectionResult, Error>;
var
  result: TContractDposCs;
  err: Error;
begin
  Tuple.Create(result, err) := GetOrLoadGid(gid);
  if err <> nil then
    Exit(TTuple.Create(Default(TElectionResult), err));

  if result = nil then
    Exit(TTuple.Create(Default(TElectionResult), EProgrammerException.CreateFmt('can''t load contract group for gid:%s, t:%s', [gid.ToString, DateTimeToStr(t)])));

  // This method doesn't exist on TContractDposCs, this will need fixing
  // Result := result.ElectionTime(t);
  Result := Default(TTuple<TElectionResult, Error>);
end;

function TContractsCs.GetForGid(gid: TGid): TContractDposCs;
begin
  FContractsMu.Acquire;
  try
    if FContracts.TryGetValue(gid, Result) then
      Exit;
    Result := nil;
  finally
    FContractsMu.Release;
  end;
end;

function TContractsCs.GetOrLoadGid(gid: TGid): TTuple<TContractDposCs, Error>;
var
  cs: TContractDposCs;
  tmp: TContractDposCs;
  err: Error;
begin
  cs := GetForGid(gid);
  if cs = nil then
  begin
    Tuple.Create(tmp, err) := ReloadGid(gid);
    if err <> nil then
      Exit(TTuple.Create(nil, err));
    Result := TTuple.Create(tmp, nil);
  end
  else
    Result := TTuple.Create(cs, nil);
end;

function TContractsCs.LoadGid(gid: TGid): Error;
var
  result: TContractDposCs;
  err: Error;
begin
  Tuple.Create(result, err) := ReloadGid(gid);
  if err <> nil then
    Result := err
  else if result = nil then
    Result := EProgrammerException.CreateFmt('load contract consensus group[%s] fail.', [gid.ToString])
  else
    Result := nil;
end;

function TContractsCs.ReloadGid(gid: TGid): TTuple<TContractDposCs, Error>;
var
  info: TGroupInfo;
  err: Error;
  cs: TContractDposCs;
begin
  FContractsMu.Acquire;
  try
    Tuple.Create(info, err) := FRw.GetMemberInfo(gid);
    if err <> nil then
      Exit(TTuple.Create(nil, err));
    if info = nil then
      Exit(TTuple.Create(nil, EProgrammerException.CreateFmt('can''t load consensus gid:%s', [gid.ToString])));

    cs := TContractDposCs.Create(info, FRw, FLog);
    FContracts.AddOrSetValue(gid, cs);
    Result := TTuple.Create(cs, nil);
  finally
    FContractsMu.Release;
  end;
end;

end.