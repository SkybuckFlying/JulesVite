unit V.Ledger.Consensus.Verifier;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  V.Common.Types,
  V.Interfaces,
  V.Interfaces.Core;

type
  TVirtualVerifier = class(TInterfacedObject, IConsensusVerifier)
  public
    function VerifyAccountProducer(block: IAccountBlock): TTuple<Boolean, Error>;
    function VerifyABsProducer(abs: TDictionary<TGid, TArray<IAccountBlock>>): TTuple<TArray<IAccountBlock>, Error>;
    function VerifySnapshotProducer(header: ISnapshotBlock): TTuple<Boolean, Error>;
  end;

function NewVirtualVerifier: IConsensusVerifier;

implementation

{ TVirtualVerifier }

function TVirtualVerifier.VerifyABsProducer(abs: TDictionary<TGid, TArray<IAccountBlock>>): TTuple<TArray<IAccountBlock>, Error>;
var
  result: TArray<IAccountBlock>;
  pair: TPair<TGid, TArray<IAccountBlock>>;
begin
  SetLength(result, 0);
  for pair in abs do
    result := result + pair.Value;
  Result := TTuple.Create(result, nil);
end;

function TVirtualVerifier.VerifyAccountProducer(block: IAccountBlock): TTuple<Boolean, Error>;
begin
  Result := TTuple.Create(True, nil);
end;

function TVirtualVerifier.VerifySnapshotProducer(header: ISnapshotBlock): TTuple<Boolean, Error>;
begin
  Result := TTuple.Create(True, nil);
end;

function NewVirtualVerifier: IConsensusVerifier;
begin
  Result := TVirtualVerifier.Create;
end;

end.