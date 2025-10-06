{
  This unit is a temporary placeholder for the Go 'log15' package.
  It provides a minimal implementation to allow the conversion of dependent units.
  The full functionality will be implemented when addressing project dependencies.
}
unit V.Log15;

interface

uses
  System.SysUtils, System.Classes;

type
  TLogLvl = (LvlCrit, LvlError, LvlWarn, LvlInfo, LvlDebug, LvlTrace);
  TLogHandler = class; // Opaque class for now
  TLogFormat = class;  // Opaque class for now

  TLogger = class
  public
    procedure Error(const Msg: string; const-var-args Args: array of const);
    procedure Crit(const Msg: string; const-var-args Args: array of const);
    class function New(const-var-args Args: array of const): TLogger;
  end;

var
  GLog: TLogger;

function LvlFromString(const lvl: string): TLogLvl;
function LvlFilterHandler(lvl: TLogLvl; handler: TLogHandler): TLogHandler;
function StreamHandler(writer: TStream; format: TLogFormat): TLogHandler;
function LogfmtFormat: TLogFormat;

implementation

{ TLogger }

procedure TLogger.Error(const Msg: string; const-var-args Args: array of const);
var
  i: Integer;
  ArgStr: string;
begin
  ArgStr := '';
  for i := 0 to High(Args) do
  begin
    if i > 0 then
      ArgStr := ArgStr + ', ';
    ArgStr := ArgStr + VarToStr(Args[i]);
  end;
  Writeln(Format('ERROR: %s [%s]', [Msg, ArgStr]));
end;

procedure TLogger.Crit(const Msg: string; const-var-args Args: array of const);
begin
  Error('CRITICAL: ' + Msg, Args);
  // In a real implementation, this would likely terminate the application.
  Halt(1);
end;

class function TLogger.New(const-var-args Args: array of const): TLogger;
begin
  Result := TLogger.Create;
end;

{ Placeholder functions }

function LvlFromString(const lvl: string): TLogLvl;
begin
  if SameText(lvl, 'crit') then Result := LvlCrit
  else if SameText(lvl, 'error') then Result := LvlError
  else if SameText(lvl, 'warn') then Result := LvlWarn
  else if SameText(lvl, 'info') then Result := LvlInfo
  else if SameText(lvl, 'debug') then Result := LvlDebug
  else if SameText(lvl, 'trace') then Result := LvlTrace
  else Result := LvlInfo; // Default
end;

function LvlFilterHandler(lvl: TLogLvl; handler: TLogHandler): TLogHandler;
begin
  Result := nil; // Placeholder
end;

function StreamHandler(writer: TStream; format: TLogFormat): TLogHandler;
begin
  Result := nil; // Placeholder
end;

function LogfmtFormat: TLogFormat;
begin
  Result := nil; // Placeholder
end;

initialization
  GLog := TLogger.New();
finalization
  GLog.Free;
end.