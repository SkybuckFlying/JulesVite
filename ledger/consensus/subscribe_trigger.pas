unit V.Ledger.Consensus.SubscribeTrigger;

interface

uses
  V.Common.Types,
  V.Ledger.Consensus.Event;

type
  ISubscribeTrigger = interface
    ['{B7E7F4B5-8D4C-4D4B-8B4A-7A5D8D3C4B8B}']
    procedure Subscribe(gid: TGid; id: string; addr: PAddress; fn: TConsensusEventFunc);
    procedure UnSubscribe(gid: TGid; id: string);
    procedure SubscribeProducers(gid: TGid; id: string; fn: TProducersEventFunc);
    procedure TriggerMineEvent(addr: TAddress): Error;
  end;

implementation

end.