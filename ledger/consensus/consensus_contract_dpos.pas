unit V.Ledger.Consensus.ConsensusContractDpos;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  V.Common.Types,
  V.Ledger.Consensus.ChainRw,
  V.Log15,
  V.Ledger.Consensus.Result,
  V.Ledger.Consensus.Dpos,
  V.Interfaces.Core,
  V.Ledger.Consensus.Core.Group;

type
  TContractDposCs = class(TInterfacedObject, IDposReader)
  private
    FInfo: TGroupInfo;
    FRw: IChainRw;
    FLog: ILogger;
  public
    constructor Create(info: TGroupInfo; rw: IChainRw; log: ILogger);
    destructor Destroy; override;
    function VerifyAccountProducer(accountBlock: IAccountBlock): TTuple<Boolean, Error>;
    function VerifyAccountsProducer(blocks: TArray<IAccountBlock>): TTuple<TArray<IAccountBlock>, Error>;
    { IDposReader }
    function ElectionIndex(index: UInt64): TTuple<TElectionResult, Error>;
    function GetInfo: TGroupInfo;
    function Time2Index(t: TDateTime): UInt64;
    function Index2Time(index: UInt64): TTuple<TDateTime, TDateTime>;
    function GenProofTime(t: UInt64): TDateTime;
    function VerifyProducer(address: TAddress; t: TDateTime): TTuple<Boolean, Error>;
  end;

implementation

{ TContractDposCs }

constructor TContractDposCs.Create(info: TGroupInfo; rw: IChainRw; log: ILogger);
begin
  FInfo := info;
  FRw := rw;
  FLog := log;
end;

destructor TContractDposCs.Destroy;
begin
  FInfo.Free;
  inherited;
end;

function TContractDposCs.ElectionIndex(index: UInt64): TTuple<TElectionResult, Error>;
begin
  // Placeholder
end;

function TContractDposCs.GenProofTime(t: UInt64): TDateTime;
begin
  // Not applicable for contract DPoS
  Result := Default(TDateTime);
end;

function TContractDposCs.GetInfo: TGroupInfo;
begin
  Result := FInfo;
end;

function TContractDposCs.Index2Time(index: UInt64): TTuple<TDateTime, TDateTime>;
begin
  Result := FInfo.TimeIndex.Index2Time(index);
end;

function TContractDposCs.Time2Index(t: TDateTime): UInt64;
begin
  Result := FInfo.TimeIndex.Time2Index(t);
end;

function TContractDposCs.VerifyAccountProducer(accountBlock: IAccountBlock): TTuple<Boolean, Error>;
begin
  // Placeholder
end;

function TContractDposCs.VerifyAccountsProducer(blocks: TArray<IAccountBlock>): TTuple<TArray<IAccountBlock>, Error>;
begin
  // Placeholder
end;

function TContractDposCs.VerifyProducer(address: TAddress; t: TDateTime): TTuple<Boolean, Error>;
begin
  // Not applicable for contract DPoS
  Result := TTuple.Create(False, EProgrammerException.Create('not implemented'));
end;

end.