unit Go.Big;

interface

uses
  System.SysUtils,
  System.Math.BigInts;

type
  IBigInt = interface
    ['{A1B2C3D4-E5F6-4A8B-9C8D-7E6F5A4B3C2D}']
    function Add(x, y: IBigInt): IBigInt;
    function Sub(x, y: IBigInt): IBigInt;
    function Mul(x, y: IBigInt): IBigInt;
    function Div(x, y: IBigInt): IBigInt;
    function Cmp(y: IBigInt): Integer;
    function SetBytes(buf: TBytes): IBigInt;
    function Bytes: TBytes;
    function Int64: Int64;
    function SetInt64(v: Int64): IBigInt;
    function ToString: string;
  end;

  TBigInt = class(TInterfacedObject, IBigInt)
  private
    FValue: TBigInteger;
  public
    constructor Create; overload;
    constructor Create(value: Int64); overload;
    class function New: IBigInt; overload;
    class function New(value: Int64): IBigInt; overload;
    function Add(x, y: IBigInt): IBigInt;
    function Sub(x, y: IBigInt): IBigInt;
    function Mul(x, y: IBigInt): IBigInt;
    function Div(x, y: IBigInt): IBigInt;
    function Cmp(y: IBigInt): Integer;
    function SetBytes(buf: TBytes): IBigInt;
    function Bytes: TBytes;
    function Int64: Int64;
    function SetInt64(v: Int64): IBigInt;
    function ToString: string;
  end;

implementation

{ TBigInt }

constructor TBigInt.Create;
begin
  FValue := TBigInteger.Zero;
end;

constructor TBigInt.Create(value: Int64);
begin
  FValue := value;
end;

class function TBigInt.New: IBigInt;
begin
  Result := TBigInt.Create;
end;

class function TBigInt.New(value: Int64): IBigInt;
begin
  Result := TBigInt.Create(value);
end;

function TBigInt.Add(x, y: IBigInt): IBigInt;
var
  xInt, yInt: TBigInteger;
begin
  xInt := (x as TBigInt).FValue;
  yInt := (y as TBigInt).FValue;
  FValue := xInt + yInt;
  Result := Self;
end;

function TBigInt.Sub(x, y: IBigInt): IBigInt;
var
  xInt, yInt: TBigInteger;
begin
  xInt := (x as TBigInt).FValue;
  yInt := (y as TBigInt).FValue;
  FValue := xInt - yInt;
  Result := Self;
end;

function TBigInt.Mul(x, y: IBigInt): IBigInt;
var
  xInt, yInt: TBigInteger;
begin
  xInt := (x as TBigInt).FValue;
  yInt := (y as TBigInt).FValue;
  FValue := xInt * yInt;
  Result := Self;
end;

function TBigInt.Div(x, y: IBigInt): IBigInt;
var
  xInt, yInt: TBigInteger;
begin
  xInt := (x as TBigInt).FValue;
  yInt := (y as TBigInt).FValue;
  FValue := xInt.Divide(yInt);
  Result := Self;
end;

function TBigInt.Cmp(y: IBigInt): Integer;
var
  yInt: TBigInteger;
begin
  yInt := (y as TBigInt).FValue;
  Result := FValue.CompareTo(yInt);
end;

function TBigInt.SetBytes(buf: TBytes): IBigInt;
begin
  FValue := TBigInteger.Create(buf);
  Result := Self;
end;

function TBigInt.Bytes: TBytes;
begin
  Result := FValue.ToByteArray;
end;

function TBigInt.Int64: Int64;
begin
  Result := FValue;
end;

function TBigInt.SetInt64(v: Int64): IBigInt;
begin
  FValue := v;
  Result := Self;
end;

function TBigInt.ToString: string;
begin
  Result := FValue.ToString;
end;

end.