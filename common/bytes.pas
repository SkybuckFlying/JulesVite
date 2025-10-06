unit V.Common.Bytes;

interface

uses
  System.SysUtils;

function PadRight(b: TBytes; size: Integer): TBytes;

implementation

function PadRight(b: TBytes; size: Integer): TBytes;
var
  l: Integer;
begin
  l := Length(b);
  if l >= size then
    Result := b
  else
  begin
    SetLength(Result, size);
    System.Move(b[0], Result[0], l);
  end;
end;

end.