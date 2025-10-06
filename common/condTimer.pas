unit V.Common.CondTimer;

interface

uses
  System.SysUtils,
  System.SyncObjs,
  System.Diagnostics;

type
  TConditionTimer = class
  private
    FCond: TCondition;
    FMutex: TMutex;
    FStopwatch: TStopwatch;
    FTimeout: Int64;
  public
    constructor Create(Mutex: TMutex);
    destructor Destroy; override;
    procedure Start(Timeout: Int64);
    function Wait: TWaitResult;
    procedure Signal;
    procedure Broadcast;
  end;

implementation

{ TConditionTimer }

constructor TConditionTimer.Create(Mutex: TMutex);
begin
  FMutex := Mutex;
  FCond := TCondition.Create;
end;

destructor TConditionTimer.Destroy;
begin
  FCond.Free;
  inherited;
end;

procedure TConditionTimer.Start(Timeout: Int64);
begin
  FTimeout := Timeout;
  FStopwatch := TStopwatch.StartNew;
end;

function TConditionTimer.Wait: TWaitResult;
var
  Elapsed, Remaining: Int64;
begin
  Elapsed := FStopwatch.ElapsedMilliseconds;
  if Elapsed >= FTimeout then
    Result := TWaitResult.wrTimeout
  else
  begin
    Remaining := FTimeout - Elapsed;
    Result := FCond.WaitFor(FMutex, Cardinal(Remaining));
  end;
end;

procedure TConditionTimer.Signal;
begin
  FCond.Signal;
end;

procedure TConditionTimer.Broadcast;
begin
  FCond.Broadcast;
end;

end.