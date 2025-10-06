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
  V.Ledger.Consensus.Result;

type
  TContractsCs = class
  private
    FRw: IChainRw;
    FContracts: TDictionary<TGid, TContractDposCs>;
    FContractsMu: TMutex;
    FLog: ILogger;
    function GetForGid(gid: TGid): TContractDposCs;
    function ReloadGid(gid: TGid): TTuple<TContractDposCs, Error>;
    function GetOrLoadGid(gid: TGid): TTuple<TContractDposCs, Error>;
  public
    constructor Create(rw: IChainRw; log: ILogger);
    function LoadGid(gid: TGid): Error;
    function ElectionTime(gid: TGid; t: TDateTime): TTuple<TElectionResult, Error>;
    function ElectionIndex(gid: TGid; index: UInt64): TTuple<TElectionResult, Error>;
  end;

implementation

uses
  System.Classes,
  V.Ledger.Chain.Index;

{ TContractsCs }

constructor TContractsCs.Create(rw: IChainRw; log: ILogger);
begin
  FRw := rw;
  FLog := log.New('gid', 'contracts');
  FContracts := TDictionary<TGid, TContractDposCs>.Create;
  FContractsMu := TMutex.Create;
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
  begin
    Result := TTuple.Create(Default(TElectionResult), err);
    Exit;
  end;
  if result = nil then
  begin
    Result := TTuple.Create(Default(TElectionResult), EProgrammerException.CreateFmt('can''t load contract group for gid:%s, t:%s', [gid.ToString, DateTimeToStr(t)]));
    Exit;
  end;
  Result := result.ElectionTime(t);
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
    begin
      Result := TTuple.Create(nil, err);
      Exit;
    end;
    Result := TTuple.Create(tmp, nil);
    Exit;
  end;
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
  info: PMemberInfo;
  err: Error;
  cs: TContractDposCs;
begin
  FContractsMu.Acquire;
  try
    Tuple.Create(info, err) := FRw.GetMemberInfo(gid);
    if err <> nil then
    begin
      Result := TTuple.Create(nil, err);
      Exit;
    end;
    if info = nil then
    begin
      Result := TTuple.Create(nil, EProgrammerException.CreateFmt('can''t load consensus gid:%s', [gid.ToString]));
      Exit;
    end;
    cs := TContractDposCs.Create(info, FRw, FLog);
    FContracts.AddOrSetValue(gid, cs);
    Result := TTuple.Create(cs, nil);
  finally
    FContractsMu.Release;
  end;
end;

end.