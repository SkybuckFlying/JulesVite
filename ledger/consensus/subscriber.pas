unit V.Ledger.Consensus.Subscriber;

interface

uses
  System.SysUtils,
  V.Common.Types,
  V.Ledger.Consensus.Event,
  V.Ledger.Consensus.SubscribeTrigger;

type
  TConsensusSubscriber = class(TInterfacedObject, ISubscribeTrigger)
  public
    procedure Subscribe(gid: TGid; id: string; addr: PAddress; fn: TConsensusEventFunc);
    procedure UnSubscribe(gid: TGid; id: string);
    procedure SubscribeProducers(gid: TGid; id: string; fn: TProducersEventFunc);
    procedure TriggerMineEvent(addr: TAddress): Error;
  end;

function NewConsensusSubscriber: ISubscribeTrigger;

implementation

{ TConsensusSubscriber }

procedure TConsensusSubscriber.Subscribe(gid: TGid; id: string; addr: PAddress; fn: TConsensusEventFunc);
begin
  // Placeholder
end;

procedure TConsensusSubscriber.SubscribeProducers(gid: TGid; id: string; fn: TProducersEventFunc);
begin
  // Placeholder
end;

procedure TConsensusSubscriber.TriggerMineEvent(addr: TAddress): Error;
begin
  Result := nil;
  // Placeholder
end;

procedure TConsensusSubscriber.UnSubscribe(gid: TGid; id: string);
begin
  // Placeholder
end;

function NewConsensusSubscriber: ISubscribeTrigger;
begin
  Result := TConsensusSubscriber.Create;
end;

end.