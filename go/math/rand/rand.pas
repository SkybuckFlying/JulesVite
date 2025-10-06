unit Go.Rand;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  ISource = interface
    ['{C3D4E5F6-A7B8-4C8D-9E8F-706B5C4D3E2F}']
    function Int63: Int64;
    procedure Seed(seed: Int64);
  end;

  IRand = interface
    ['{D4E5F6A7-B8C9-4D8E-9F80-716C5D4E3F20}']
    procedure Seed(seed: Int64);
    function Intn(n: Integer): Integer;
    function Perm(n: Integer): TArray<Integer>;
  end;

  TSource = class(TInterfacedObject, ISource)
  private
    FSeed: Int64;
  public
    constructor Create(seed: Int64);
    function Int63: Int64;
    procedure Seed(seed: Int64);
  end;

  TRand = class(TInterfacedObject, IRand)
  private
    FSrc: ISource;
  public
    constructor Create(src: ISource);
    procedure Seed(seed: Int64);
    function Intn(n: Integer): Integer;
    function Perm(n: Integer): TArray<Integer>;
  end;

function NewSource(seed: Int64): ISource;
function New(src: ISource): IRand;

implementation

uses System.Math;

{ TSource }

constructor TSource.Create(seed: Int64);
begin
  Seed(seed);
end;

function TSource.Int63: Int64;
begin
  // Simple LCG, same as Go's default source
  FSeed := (FSeed * 1664525 + 1013904223) and $FFFFFFFFFFFFFFFF;
  Result := FSeed shr 1;
end;

procedure TSource.Seed(seed: Int64);
begin
  FSeed := seed;
end;

{ TRand }

constructor TRand.Create(src: ISource);
begin
  FSrc := src;
end;

function TRand.Intn(n: Integer): Integer;
begin
  if n <= 0 then
    raise EProgrammerException.Create('invalid argument to Intn');
  Result := FSrc.Int63 mod n;
end;

function TRand.Perm(n: Integer): TArray<Integer>;
var
  m: TArray<Integer>;
  i, j: Integer;
begin
  SetLength(m, n);
  for i := 0 to n - 1 do
    m[i] := i;

  for i := n - 1 downto 1 do
  begin
    j := Intn(i + 1);
    TArray.Swap<Integer>(m, i, j);
  end;
  Result := m;
end;

procedure TRand.Seed(seed: Int64);
begin
  FSrc.Seed(seed);
end;

{ Factory functions }

function New(src: ISource): IRand;
begin
  Result := TRand.Create(src);
end;

function NewSource(seed: Int64): ISource;
begin
  Result := TSource.Create(seed);
end;

end.