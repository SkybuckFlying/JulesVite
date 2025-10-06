unit Go.LevelDB.Util;

interface

uses
  System.SysUtils;

type
  IBytesPrefix = interface
    ['{E5F6A7B8-C9D0-4E8F-9081-726D5E4F3011}']
    function Limit: TBytes;
    function Start: TBytes;
  end;

  TBytesPrefix = class(TInterfacedObject, IBytesPrefix)
  private
    FPrefix: TBytes;
  public
    constructor Create(prefix: TBytes);
    class function New(prefix: TBytes): IBytesPrefix;
    function Limit: TBytes;
    function Start: TBytes;
  end;

implementation

{ TBytesPrefix }

constructor TBytesPrefix.Create(prefix: TBytes);
begin
  FPrefix := prefix;
end;

class function TBytesPrefix.New(prefix: TBytes): IBytesPrefix;
begin
  Result := TBytesPrefix.Create(prefix);
end;

function TBytesPrefix.Limit: TBytes;
var
  limitBytes: TBytes;
  i: Integer;
begin
  SetLength(limitBytes, Length(FPrefix));
  limitBytes := FPrefix;
  for i := Length(limitBytes) - 1 downto 0 do
  begin
    Inc(limitBytes[i]);
    if limitBytes[i] <> 0 then
    begin
      Result := Copy(limitBytes, 0, i + 1);
      Exit;
    end;
  end;
  Result := nil; // Overflow
end;

function TBytesPrefix.Start: TBytes;
begin
  Result := FPrefix;
end;

end.