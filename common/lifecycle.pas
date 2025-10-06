{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/common/lifecycle.go
}
unit V.Common.Lifecycle;

interface

uses
  System.SysUtils;

const
  StatusOrigin   = 0;
  StatusIniting  = 1;
  StatusInited   = 2;
  StatusStarting = 3;
  StatusStarted  = 4;
  StatusStopping = 5;
  StatusStopped  = 6;

type
  TLifecycleStatus = record
  private
    FStatus: Integer;
  public
    function PreInit: Boolean;
    function PostInit: Boolean;
    function PreStart: Boolean;
    function PostStart: Boolean;
    function PreStop: Boolean;
    function PostStop: Boolean;
    function Stopped: Boolean;
    function GetStatus: Integer;
  end;

  ILifecycle = interface
    ['{B4E2B2D1-6C7A-4C1F-9B0F-3F0E6A2D7E5B}']
    procedure Init;
    procedure Start;
    procedure Stop;
    function GetStatus: Integer;
  end;

implementation

{ TLifecycleStatus }

function TLifecycleStatus.PreInit: Boolean;
begin
  Result := TInterlocked.CompareExchange(FStatus, StatusIniting, StatusOrigin) = StatusOrigin;
end;

function TLifecycleStatus.PostInit: Boolean;
begin
  Result := TInterlocked.CompareExchange(FStatus, StatusInited, StatusIniting) = StatusIniting;
end;

function TLifecycleStatus.PreStart: Boolean;
begin
  Result := TInterlocked.CompareExchange(FStatus, StatusStarting, StatusInited) = StatusInited;
end;

function TLifecycleStatus.PostStart: Boolean;
begin
  Result := TInterlocked.CompareExchange(FStatus, StatusStarted, StatusStarting) = StatusStarting;
end;

function TLifecycleStatus.PreStop: Boolean;
begin
  Result := TInterlocked.CompareExchange(FStatus, StatusStopping, StatusStarted) = StatusStarted;
end;

function TLifecycleStatus.PostStop: Boolean;
begin
  Result := TInterlocked.CompareExchange(FStatus, StatusStopped, StatusStopping) = StatusStopping;
end;

function TLifecycleStatus.Stopped: Boolean;
begin
  Result := (FStatus = StatusStopped) or (FStatus = StatusStopping);
end;

function TLifecycleStatus.GetStatus: Integer;
begin
  Result := FStatus;
end;

end.