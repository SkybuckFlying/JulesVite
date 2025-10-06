{
  This unit is a temporary placeholder for the Go 'blake2b' package.
  It provides a minimal implementation to allow the conversion of dependent units.
}
unit V.Crypto.Blake2b;

interface

uses
  System.SysUtils;

type
  IHash = interface
    ['{D7C3B5F0-4E6A-4E9A-9B7C-2C5E7A2D3F5E}']
    procedure Write(const data: TBytes);
    function Sum(const b: TBytes): TBytes;
    procedure Reset;
  end;

function New(size: Integer; key: TBytes): IHash;
function New256(key: TBytes): IHash;
function New512(key: TBytes): IHash;
function Sum512(const Data: TBytes): TBytes;

implementation

type
  THash = class(TInterfacedObject, IHash)
  private
    FSize: Integer;
  public
    constructor Create(ASize: Integer);
    procedure Write(const data: TBytes);
    function Sum(const b: TBytes): TBytes;
    procedure Reset;
  end;

constructor THash.Create(ASize: Integer);
begin
  FSize := ASize;
end;

procedure THash.Write(const data: TBytes);
begin
  // Placeholder implementation
end;

function THash.Sum(const b: TBytes): TBytes;
var
  hashResult: TBytes;
begin
  SetLength(hashResult, FSize);
  FillChar(hashResult[0], FSize, 0);
  Result := b + hashResult;
end;

procedure THash.Reset;
begin
  // Placeholder implementation
end;

function New(size: Integer; key: TBytes): IHash;
begin
  Result := THash.Create(size);
end;

function New256(key: TBytes): IHash;
begin
  Result := THash.Create(32);
end;

function New512(key: TBytes): IHash;
begin
  Result := THash.Create(64);
end;

function Sum512(const Data: TBytes): TBytes;
var
  h: IHash;
begin
  h := New512(nil);
  h.Write(Data);
  Result := h.Sum(nil);
end;

end.