unit V.Common.Log;

interface

uses
  System.SysUtils,
  V.Log15,
  V.Lumberjack;

type
  TLog = class
  public
    class procedure Setup(cfg: TObject); // Placeholder for config type
  end;

implementation

{ TLog }

class procedure TLog.Setup(cfg: TObject);
var
  log: ILogger;
  handler: TObject; // Placeholder for handler type
begin
  log := TLog15.New;
  // handler := TLumberjackLogger.New; // This would be the real implementation
  // log.SetHandler(handler);
end;

end.