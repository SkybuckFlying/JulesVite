{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/common/log.go
}
unit V.Common.Log;

interface

uses
  System.SysUtils, V.Log15;

function LogHandler(const path, subDir, filename, lvl: string): TLogHandler;

implementation

uses
  System.IOUtils, V.Lumberjack;

function MakeDefaultLogger(const absFilePath: string): TLogger;
begin
  Result := TLogger.Create(absFilePath);
  Result.MaxSize := 100;
  Result.MaxBackups := 14;
  Result.MaxAge := 14;
  Result.Compress := True;
  Result.LocalTime := True;
end;

function LogHandler(const path, subDir, filename, lvl: string): TLogHandler;
var
  logLevel: TLogLvl;
  absFilename: string;
  outWriter: TLogger;
begin
  logLevel := LvlFromString(lvl);
  absFilename := TPath.Combine(path, subDir, filename);
  outWriter := MakeDefaultLogger(absFilename);
  Result := LvlFilterHandler(logLevel, StreamHandler(outWriter, LogfmtFormat()));
end;

end.