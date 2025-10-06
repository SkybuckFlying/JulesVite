unit V.Ledger.Consensus.Core.Vote;

interface

uses
  System.SysUtils,
  System.Generics.Defaults,
  System.Generics.Collections,
  Go.Big,
  V.Common.Types;

type
  TVoteType = (
    NORMAL,
    SUCCESS_RATE_PROMOTION,
    SUCCESS_RATE_DEMOTION,
    RANDOM_PROMOTION
  );

  PVote = ^TVote;
  TVote = record
    Name: string;
    Addr: TAddress;
    Balance: IBigInt;
    &Type: TArray<TVoteType>;
  end;

  TByBalance = class(TComparer<PVote>)
  public
    function Compare(const Left, Right: PVote): Integer; override;
  end;

implementation

{ TByBalance }

function TByBalance.Compare(const Left, Right: PVote): Integer;
var
  r: Integer;
begin
  r := Right.Balance.Cmp(Left.Balance);
  if r = 0 then
    Result := AnsiString.Compare(Left.Name, Right.Name)
  else
    Result := r;
end;

end.