program GoVite;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  V.Common.Math.Integer in 'common\math\integer.pas';

begin
  try
    // This is a placeholder for the main program logic.
    // For now, it just demonstrates that the unit can be included.
    Writeln('Delphi project file created.');
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.