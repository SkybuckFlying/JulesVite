{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/common/goroutine.go
}
unit V.Common.GoRoutine;

interface

uses
  System.SysUtils;

type
  TGoProc = reference to procedure;

// Go executes a procedure in a background task with exception handling.
procedure Go(Proc: TGoProc);

implementation

uses
  System.Threading, V.Log15;

procedure CatchAndLog;
var
  E: Exception;
begin
  E := ExceptObject as Exception;
  if E <> nil then
  begin
    GLog.Error('panic', 'err', E.Message, 'withstack', E.StackTrace);
    Writeln(E.ClassName, ': ', E.Message);
    Writeln(E.StackTrace);
    // Re-raising the exception is important to avoid silent failures.
    raise;
  end;
end;

procedure Wrap(Proc: TGoProc);
begin
  try
    Proc();
  except
    on E: Exception do
      CatchAndLog;
  end;
end;

procedure Go(Proc: TGoProc);
begin
  TTask.Run(
    procedure
    begin
      Wrap(Proc);
    end);
end;

end.