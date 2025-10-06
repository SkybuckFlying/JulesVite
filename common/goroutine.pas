unit V.Common.GoRoutine;

interface

uses
  System.SysUtils,
  System.Threading,
  V.Log15;

procedure Go(proc: TProc);

implementation

procedure Go(proc: TProc);
begin
  TTask.Run(
    procedure
    begin
      try
        proc;
      except
        on E: Exception do
        begin
          // In a real implementation, you'd use a shared logger instance.
          TLog15.New('module', 'goroutine').Error('goroutine panic', 'err', E.Message);
        end;
      end;
    end
  );
end;

end.