unit V.Crypto.Rand;

interface

uses
  System.SysUtils;

function Read(var b: TBytes): TTuple<Integer, Error>;

implementation

uses
  System.Security.Cryptography;

function Read(var b: TBytes): TTuple<Integer, Error>;
var
  rng: TRandom;
begin
  rng := TRandom.Create;
  try
    rng.NextBytes(b);
    Result := TTuple.Create(Length(b), nil);
  finally
    rng.Free;
  end;
end;

end.