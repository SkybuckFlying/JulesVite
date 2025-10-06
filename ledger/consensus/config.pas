unit V.Ledger.Consensus.Config;

interface

type
  PConsensusCfg = ^TConsensusCfg;
  TConsensusCfg = record
  end;

function DefaultCfg: PConsensusCfg;
function Cfg: PConsensusCfg;

implementation

function DefaultCfg: PConsensusCfg;
begin
  New(Result);
end;

function Cfg: PConsensusCfg;
begin
  New(Result);
end;

end.