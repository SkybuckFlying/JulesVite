program Test;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  V.VM.Params in 'vm/params.pas',
  V.VM.GasTable in 'vm/gas_table.pas';

begin
  try
    Writeln('Test program compiled.');
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.