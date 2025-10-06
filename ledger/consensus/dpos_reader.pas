unit V.Ledger.Consensus.DposReader;

interface

uses
  System.SysUtils,
  V.Common.Types,
  V.Ledger.Consensus.Snapshot,
  V.Ledger.Consensus.ConsensusContract,
  V.Ledger.Consensus.Dpos,
  V.Log15,
  V.Ledger.Consensus.ConsensusContractDpos;

type
  TDposReader = class
  private
    FSnapshot: ISnapshotCs;
    FContracts: TContractsCs;
    FMLog: ILogger;
  public
    constructor Create(snapshot: ISnapshotCs; contracts: TContractsCs; log: ILogger);
    function GetDposConsensus(gid: TGid): TTuple<IDposReader, Error>;
  end;

implementation

{ TDposReader }

constructor TDposReader.Create(snapshot: ISnapshotCs; contracts: TContractsCs; log: ILogger);
begin
  FSnapshot := snapshot;
  FContracts := contracts;
  FMLog := log;
end;

function TDposReader.GetDposConsensus(gid: TGid): TTuple<IDposReader, Error>;
var
  contractDpos: TContractDposCs;
  err: Error;
begin
  if gid = GID_Snapshot then
  begin
    Result := TTuple.Create(FSnapshot as IDposReader, nil);
    Exit;
  end;

  Tuple.Create(contractDpos, err) := FContracts.GetOrLoadGid(gid);
  if err <> nil then
  begin
    Result := TTuple.Create(nil, err);
    Exit;
  end;

  Result := TTuple.Create(contractDpos as IDposReader, nil);
end;

end.