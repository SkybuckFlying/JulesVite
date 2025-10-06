unit V.Ledger.Consensus.Event;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Go.Context,
  V.Common.Types,
  V.Ledger.Consensus.Core.Group,
  V.Ledger.Consensus.Result;

type
  PConsensusEvent = ^TConsensusEvent;
  TConsensusEvent = record
    Gid: TGid;
    Address: TAddress;
    Stime: TDateTime;
    Etime: TDateTime;
    Timestamp: TDateTime;
    VoteTime: TDateTime;
    PeriodStime: TDateTime;
    PeriodEtime: TDateTime;
  end;

  TProducersEvent = record
    Addrs: TArray<TAddress>;
    Index: UInt64;
    Gid: TGid;
  end;

  TConsensusEventFunc = reference to procedure(event: TConsensusEvent);

  TSubscribeEvent = record
    addr: PAddress;
    gid: TGid;
    fn: TConsensusEventFunc;
    procedure Trigger(ctx: IContext; result: TElectionResult; voteTime: TDateTime);
  private
    procedure TriggerAll(ctx: IContext; result: TElectionResult; voteTime: TDateTime);
    procedure TriggerAddr(ctx: IContext; result: TElectionResult; voteTime: TDateTime);
  end;

  TProducersEventFunc = reference to procedure(event: TProducersEvent);

  TProducerSubscribeEvent = record
    gid: TGid;
    fn: TProducersEventFunc;
    procedure Trigger(ctx: IContext; result: TElectionResult; voteTime: TDateTime);
  end;

function NewConsensusEvent(r: TElectionResult; p: TMemberPlan; gid: TGid; voteTime: TDateTime): TConsensusEvent;

implementation

uses
  System.Threading,
  System.DateUtils;

{ TSubscribeEvent }

procedure TSubscribeEvent.Trigger(ctx: IContext; result: TElectionResult; voteTime: TDateTime);
begin
  if addr = nil then
    TriggerAll(ctx, result, voteTime)
  else
    TriggerAddr(ctx, result, voteTime);
end;

procedure TSubscribeEvent.TriggerAll(ctx: IContext; result: TElectionResult; voteTime: TDateTime);
var
  p: TMemberPlan;
  now: TDateTime;
  sub: TTimeSpan;
begin
  for p in result.Plans do
  begin
    now := Now;
    sub := p.STime - now;
    if (sub.TotalSeconds + 1) < 0 then
      Continue;
    if sub.TotalMilliseconds > 10 then
    begin
      if TEvent.WaitFor(ctx.Done, Trunc(sub.TotalMilliseconds)) = wrSignaled then
        Exit;
    end;
    fn(NewConsensusEvent(result, p, gid, voteTime));
  end;
end;

procedure TSubscribeEvent.TriggerAddr(ctx: IContext; result: TElectionResult; voteTime: TDateTime);
var
  p: TMemberPlan;
  now: TDateTime;
  sub: TTimeSpan;
begin
  for p in result.Plans do
  begin
    if p.Member = addr^ then
    begin
      now := Now;
      sub := p.STime - now;
      if (sub.TotalSeconds + 1) < 0 then
        Continue;
      if sub.TotalMilliseconds > 10 then
      begin
        if TEvent.WaitFor(ctx.Done, Trunc(sub.TotalMilliseconds)) = wrSignaled then
          Exit;
      end;
      fn(NewConsensusEvent(result, p, gid, voteTime));
    end;
  end;
end;

{ TProducerSubscribeEvent }

procedure TProducerSubscribeEvent.Trigger(ctx: IContext; result: TElectionResult; voteTime: TDateTime);
var
  r: TArray<TAddress>;
  v: TMemberPlan;
  event: TProducersEvent;
begin
  SetLength(r, 0);
  for v in result.Plans do
    r := r + [v.Member];
  event.Addrs := r;
  event.Index := result.Index;
  event.Gid := gid;
  fn(event);
end;

function NewConsensusEvent(r: TElectionResult; p: TMemberPlan; gid: TGid; voteTime: TDateTime): TConsensusEvent;
begin
  Result.Gid := gid;
  Result.Address := p.Member;
  Result.Stime := p.STime;
  Result.Etime := p.ETime;
  Result.Timestamp := p.STime;
  Result.VoteTime := voteTime;
  Result.PeriodStime := r.STime;
  Result.PeriodEtime := r.ETime;
end;

end.