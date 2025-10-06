unit V.Ledger.Consensus.Trigger;

interface

uses
  System.SysUtils,
  Go.Context,
  V.Common.Types,
  V.Ledger.Pool.Lock,
  V.Ledger.Consensus.Dpos,
  V.Ledger.Consensus.SubscribeTrigger;

type
  TTrigger = class
  public
    constructor Create(rollback: IChainRollback);
    procedure Update(ctx: IContext; gid: TGid; consensus: IDposReader; trigger: ISubscribeTrigger);
  end;

function NewTrigger(rollback: IChainRollback): TTrigger;

implementation

{ TTrigger }

constructor TTrigger.Create(rollback: IChainRollback);
begin
  // Placeholder
end;

procedure TTrigger.Update(ctx: IContext; gid: TGid; consensus: IDposReader; trigger: ISubscribeTrigger);
begin
  // Placeholder
end;

function NewTrigger(rollback: IChainRollback): TTrigger;
begin
  Result := TTrigger.Create(rollback);
end;

end.