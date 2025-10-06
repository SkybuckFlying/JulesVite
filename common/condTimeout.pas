{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/common/condTimeout.go
}
unit V.Common.CondTimeout;

interface

uses
  System.SysUtils, System.SyncObjs, System.Classes;

type
  ETimeout = class(Exception);

  TTimeoutCond = class
  private
    FNotifyNum: Integer;
    FLock: TCriticalSection;
    FSignal: TEvent;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Wait;
    function WaitTimeout(Timeout: Cardinal): Boolean;
    procedure Broadcast;
    procedure Signal;
  end;

implementation

{ TTimeoutCond }

constructor TTimeoutCond.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FSignal := TEvent.Create(nil, True, False, '');
end;

destructor TTimeoutCond.Destroy;
begin
  FSignal.Free;
  FLock.Free;
  inherited Destroy;
end;

procedure TTimeoutCond.Wait;
begin
  if TInterlocked.Exchange(FNotifyNum, 0) > 0 then
    Exit;

  FSignal.WaitFor(INFINITE);
end;

function TTimeoutCond.WaitTimeout(Timeout: Cardinal): Boolean;
begin
  if TInterlocked.Exchange(FNotifyNum, 0) > 0 then
    Exit(True);

  Result := FSignal.WaitFor(Timeout) = wrSignaled;
end;

procedure TTimeoutCond.Broadcast;
var
  OldSignal: TEvent;
begin
  TInterlocked.Increment(FNotifyNum);
  FLock.Enter;
  try
    OldSignal := FSignal;
    FSignal := TEvent.Create(nil, True, False, '');
    OldSignal.SetEvent;
    OldSignal.Free;
  finally
    FLock.Leave;
  end;
end;

procedure TTimeoutCond.Signal;
begin
  TInterlocked.Increment(FNotifyNum);
  FLock.Enter;
  try
    FSignal.SetEvent;
  finally
    FLock.Leave;
  end;
end;

end.