program TestContracts;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  V.VM.Contracts.ABI in 'vm/contracts/abi/abi.pas',
  V.VM.Contracts in 'vm/contracts/contracts.pas';

begin
  try
    Writeln('Test program compiled.');
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.