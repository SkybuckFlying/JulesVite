unit V.Common.HexUtil;

interface

uses
  System.SysUtils;

type
  TBig = record // Placeholder for Go's big.Int
  end;

function Decode(s: string): TBytes;
function Encode(b: TBytes): string;
function DecodeBig(s: string): TTuple<TBig, Error>;

implementation

uses
  System.NetEncoding;

function Decode(s: string): TBytes;
var
  Hex: string;
begin
  if s.StartsWith('0x') or s.StartsWith('0X') then
    Hex := s.Substring(2)
  else
    Hex := s;
  Result := THex.Decode(Hex);
end;

function Encode(b: TBytes): string;
begin
  Result := '0x' + THex.Encode(b);
end;

function DecodeBig(s: string): TTuple<TBig, Error>;
begin
  // Placeholder implementation
  Result := Default(TTuple<TBig, Error>);
end;

end.