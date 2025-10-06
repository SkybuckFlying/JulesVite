unit V.Common.CondTimeout;

interface

uses
  System.SysUtils,
  System.SyncObjs,
  System.Diagnostics;

type
  TConditionTimeout = class
  private
    FCond: TCondition;
    FMutex: TMutex;
  public
    constructor Create(Mutex: TMutex);
    destructor Destroy; override;
    function Wait(Timeout: Cardinal): TWaitResult;
    procedure Signal;
    procedure Broadcast;
  end;

implementation

{ TConditionTimeout }

constructor TConditionTimeout.Create(Mutex: TMutex);
begin
  FMutex := Mutex;
  FCond := TCondition.Create;
end;

destructor TConditionTimeout.Destroy;
begin
  FCond.Free;
  inherited;
end;

function TConditionTimeout.Wait(Timeout: Cardinal): TWaitResult;
begin
  Result := FCond.WaitFor(FMutex, Timeout);
end;

procedure TConditionTimeout.Signal;
begin
  FCond.Signal;
end;

procedure TConditionTimeout.Broadcast;
begin
  FCond.Broadcast;
end;

end.