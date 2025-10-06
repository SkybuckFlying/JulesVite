unit V.Hash.FNV;

interface

uses
  System.SysUtils;

type
  IHash32 = interface
    ['{C3D4E5F6-A7B8-4C8D-9E8F-706B5C4D3E2D}']
    procedure Write(const buffer: TBytes);
    function Sum32: UInt32;
  end;

function New32: IHash32;

implementation

const
  Offset32 = 2166136261;
  Prime32 = 16777619;

type
  THash32 = class(TInterfacedObject, IHash32)
  private
    FHash: UInt32;
  public
    constructor Create;
    procedure Write(const buffer: TBytes);
    function Sum32: UInt32;
  end;

{ THash32 }

constructor THash32.Create;
begin
  FHash := Offset32;
end;

procedure THash32.Write(const buffer: TBytes);
var
  b: Byte;
begin
  for b in buffer do
  begin
    FHash := FHash * Prime32;
    FHash := FHash xor b;
  end;
end;

function THash32.Sum32: UInt32;
begin
  Result := FHash;
end;

function New32: IHash32;
begin
  Result := THash32.Create;
end;

end.