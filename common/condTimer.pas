{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/common/condTimer.go
}
unit V.Common.CondTimer;

interface

uses
  System.SysUtils, System.SyncObjs, System.Classes, System.Threading;

type
  TCondTimer = class
  private
    FMonitor: TObject;
    FNotifyNum: Integer;
    FStopEvent: TEvent;
    FTimerThread: TThread;
    FInterval: Cardinal;
    procedure TimerLoop;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Wait;
    procedure Broadcast;
    procedure Signal;
    procedure Start(AInterval: Cardinal);
    procedure Stop;
  end;

implementation

{ TCondTimer }

constructor TCondTimer.Create;
begin
  inherited Create;
  FMonitor := TObject.Create;
  FStopEvent := TEvent.Create(nil, True, False, '');
end;

destructor TCondTimer.Destroy;
begin
  Stop;
  FStopEvent.Free;
  FMonitor.Free;
  inherited Destroy;
end;

procedure TCondTimer.Wait;
begin
  if TInterlocked.Exchange(FNotifyNum, 0) > 0 then
    Exit;

  TMonitor.Enter(FMonitor);
  try
    TMonitor.Wait(FMonitor, INFINITE);
  finally
    TMonitor.Exit(FMonitor);
  end;
end;

procedure TCondTimer.Broadcast;
begin
  TInterlocked.Increment(FNotifyNum);
  TMonitor.Enter(FMonitor);
  try
    TMonitor.PulseAll(FMonitor);
  finally
    TMonitor.Exit(FMonitor);
  end;
end;

procedure TCondTimer.Signal;
begin
  TInterlocked.Increment(FNotifyNum);
  TMonitor.Enter(FMonitor);
  try
    TMonitor.Pulse(FMonitor);
  finally
    TMonitor.Exit(FMonitor);
  end;
end;

procedure TCondTimer.TimerLoop;
begin
  while FStopEvent.WaitFor(FInterval) <> wrSignaled do
  begin
    Broadcast;
  end;
end;

procedure TCondTimer.Start(AInterval: Cardinal);
begin
  TMonitor.Enter(FMonitor);
  try
    if Assigned(FTimerThread) and (not FTimerThread.IsFinished) then
      Exit;

    FInterval := AInterval;
    FStopEvent.ResetEvent;
    FTimerThread := TThread.CreateAnonymousThread(TimerLoop);
    FTimerThread.Start;
  finally
    TMonitor.Exit(FMonitor);
  end;
end;

procedure TCondTimer.Stop;
begin
  TMonitor.Enter(FMonitor);
  try
    if not Assigned(FTimerThread) then
      Exit;
    FStopEvent.SetEvent;
  finally
    TMonitor.Exit(FMonitor);
  end;

  FTimerThread.WaitFor;
  FTimerThread := nil;

  Broadcast;
end;

end.