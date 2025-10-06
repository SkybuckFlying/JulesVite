{
  This unit is a temporary placeholder for the Go 'vm/vm.go' config.
  It provides a minimal TVMConfig record and a global NodeConfig variable
  to allow the conversion of dependent units.
}
unit V.VM.Config;

interface

uses
  System.SysUtils, V.Log15;

type
  TVMConfig = record
    IsDebug: Boolean;
    Log: TLogger;
    InterpreterLog: TLogger;
  end;

var
  NodeConfig: TVMConfig;

implementation

initialization
  NodeConfig.IsDebug := False;
  NodeConfig.Log := GLog;
  NodeConfig.InterpreterLog := GLog;
end.