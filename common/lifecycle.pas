unit V.Common.Lifecycle;

interface

uses
  System.SysUtils,
  System.SyncObjs;

type
  TLifecycleStatus = record
  private
    FMutex: TMutex;
    FStarted: Boolean;
    FInit: Boolean;
  public
    procedure Init;
    function PreInit: Boolean;
    procedure PostInit;
    function PreStart: Boolean;
    procedure PostStart;
    function PreStop: Boolean;
    procedure PostStop;
  end;

implementation

{ TLifecycleStatus }

procedure TLifecycleStatus.Init;
begin
  FMutex := TMutex.Create;
end;

function TLifecycleStatus.PreInit: Boolean;
begin
  FMutex.Acquire;
  try
    if FInit then
    begin
      Result := False;
      Exit;
    end;
    Result := True;
  finally
    FMutex.Release;
  end;
end;

procedure TLifecycleStatus.PostInit;
begin
  FMutex.Acquire;
  try
    FInit := True;
  finally
    FMutex.Release;
  end;
end;

function TLifecycleStatus.PreStart: Boolean;
begin
  FMutex.Acquire;
  try
    if FStarted then
    begin
      Result := False;
      Exit;
    end;
    Result := True;
  finally
    FMutex.Release;
  end;
end;

procedure TLifecycleStatus.PostStart;
begin
  FMutex.Acquire;
  try
    FStarted := True;
  finally
    FMutex.Release;
  end;
end;

function TLifecycleStatus.PreStop: Boolean;
begin
  FMutex.Acquire;
  try
    if not FStarted then
    begin
      Result := False;
      Exit;
    end;
    Result := True;
  finally
    FMutex.Release;
  end;
end;

procedure TLifecycleStatus.PostStop;
begin
  FMutex.Acquire;
  try
    FStarted := False;
  finally
    FMutex.Release;
  end;
end;

end.