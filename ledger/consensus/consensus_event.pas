{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/ledger/consensus/consensus_event.go
}
unit V.Ledger.Consensus.Event;

interface

uses
  System.SysUtils, System.Classes,
  V.Common.Types, V.Ledger.Consensus.Core, V.Ledger.Consensus.Result;

type
  TEvent = record
    Gid: TGid;
    Address: TAddress;
    STime, ETime, Timestamp, VoteTime: TDateTime;
    PeriodStime, PeriodEtime: TDateTime;
  end;

  TProducersEvent = record
    Addrs: TArray<TAddress>;
    Index: UInt64;
    Gid: TGid;
  end;

  TEventCallback = procedure(const Event: TEvent);
  TProducersEventCallback = procedure(const Event: TProducersEvent);

  TSubscribeEvent = class
  private
    FAddr: PAddress;
    FGid: TGid;
    FFn: TEventCallback;
    procedure TriggerAll(Ctx: TObject; Result: PElectionResult; VoteTime: TDateTime);
    procedure TriggerAddr(Ctx: TObject; Result: PElectionResult; VoteTime: TDateTime);
  public
    constructor Create(AAddr: PAddress; const AGid: TGid; AFn: TEventCallback);
    procedure Trigger(Ctx: TObject; Result: PElectionResult; VoteTime: TDateTime);
  end;

  TProducerSubscribeEvent = class
  private
    FGid: TGid;
    FFn: TProducersEventCallback;
  public
    constructor Create(const AGid: TGid; AFn: TProducersEventCallback);
    procedure Trigger(Ctx: TObject; Result: PElectionResult; VoteTime: TDateTime);
  end;

function NewConsensusEvent(R: PElectionResult; P: PMemberPlan; const Gid: TGid; VoteTime: TDateTime): TEvent;

implementation

uses System.Threading;

{ TSubscribeEvent }

constructor TSubscribeEvent.Create(AAddr: PAddress; const AGid: TGid; AFn: TEventCallback);
begin
  inherited Create;
  FAddr := AAddr;
  FGid := AGid;
  FFn := AFn;
end;

procedure TSubscribeEvent.Trigger(Ctx: TObject; Result: PElectionResult; VoteTime: TDateTime);
begin
  if FAddr = nil then
    TriggerAll(Ctx, Result, VoteTime)
  else
    TriggerAddr(Ctx, Result, VoteTime);
end;

procedure TSubscribeEvent.TriggerAll(Ctx: TObject; Result: PElectionResult; VoteTime: TDateTime);
var
  p: PMemberPlan;
  sub: TTimeSpan;
begin
  for p in Result.Plans do
  begin
    sub := p.STime - Now;
    if sub.TotalSeconds < -1 then Continue;
    if sub.TotalMilliseconds > 10 then
      TThread.Sleep(sub); // Simplified wait
    FFn(NewConsensusEvent(Result, p, FGid, VoteTime));
  end;
end;

procedure TSubscribeEvent.TriggerAddr(Ctx: TObject; Result: PElectionResult; VoteTime: TDateTime);
var
  p: PMemberPlan;
  sub: TTimeSpan;
begin
  for p in Result.Plans do
  begin
    if CompareMem(@p.Member, FAddr, SizeOf(TAddress)) then
    begin
      sub := p.STime - Now;
      if sub.TotalSeconds < -1 then Continue;
      if sub.TotalMilliseconds > 10 then
        TThread.Sleep(sub); // Simplified wait
      FFn(NewConsensusEvent(Result, p, FGid, VoteTime));
    end;
  end;
end;

{ TProducerSubscribeEvent }

constructor TProducerSubscribeEvent.Create(const AGid: TGid; AFn: TProducersEventCallback);
begin
  inherited Create;
  FGid := AGid;
  FFn := AFn;
end;

procedure TProducerSubscribeEvent.Trigger(Ctx: TObject; Result: PElectionResult; VoteTime: TDateTime);
var
  r: TArray<TAddress>;
  i: Integer;
  v: PMemberPlan;
begin
  SetLength(r, Length(Result.Plans));
  for i := 0 to High(Result.Plans) do
  begin
    v := Result.Plans[i];
    r[i] := v.Member;
  end;
  FFn(TProducersEvent.Create(r, Result.Index, FGid));
end;

function NewConsensusEvent(R: PElectionResult; P: PMemberPlan; const Gid: TGid; VoteTime: TDateTime): TEvent;
begin
  Result.Gid := Gid;
  Result.Address := P.Member;
  Result.STime := P.STime;
  Result.ETime := P.ETime;
  Result.Timestamp := P.STime;
  Result.VoteTime := VoteTime;
  Result.PeriodStime := R.STime;
  Result.PeriodEtime := R.ETime;
end;

end.