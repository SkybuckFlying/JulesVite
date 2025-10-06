{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/common/bloom/bucket.go
}
unit V.Common.Bloom.Bucket;

interface

uses
  System.SysUtils;

type
  // TBuckets is a fast, space-efficient array of buckets.
  TBuckets = class
  private
    FData: TBytes;
    FBucketSize: Byte;
    FMax: Byte;
    FCount: Cardinal;
    FTotal: Cardinal;
    function GetBits(Offset, Length: Cardinal): UInt32;
    procedure SetBits(Offset, Length, Bits: UInt32);
  public
    constructor Create(ACount: Cardinal; ABucketSize: Byte);
    function MaxBucketValue: Byte;
    function FullRatio: Double;
    function Set(Bucket: Cardinal; Value: Byte): TBuckets;
    function Get(Bucket: Cardinal): UInt32;
    procedure Reset;
  end;

implementation

{ TBuckets }

constructor TBuckets.Create(ACount: Cardinal; ABucketSize: Byte);
begin
  inherited Create;
  FTotal := ACount;
  FCount := 0;
  SetLength(FData, (ACount * ABucketSize + 7) div 8);
  FBucketSize := ABucketSize;
  FMax := (1 shl ABucketSize) - 1;
end;

function TBuckets.MaxBucketValue: Byte;
begin
  Result := FMax;
end;

function TBuckets.FullRatio: Double;
begin
  if FTotal = 0 then
    Result := 0
  else
    Result := FCount / FTotal;
end;

function TBuckets.Set(Bucket: Cardinal; Value: Byte): TBuckets;
var
  clampedValue: Byte;
begin
  clampedValue := Value;
  if clampedValue > FMax then
    clampedValue := FMax;

  SetBits(Bucket * FBucketSize, FBucketSize, clampedValue);
  Inc(FCount);
  Result := Self;
end;

function TBuckets.Get(Bucket: Cardinal): UInt32;
begin
  Result := GetBits(Bucket * FBucketSize, FBucketSize);
end;

procedure TBuckets.Reset;
var
  i: Integer;
begin
  for i := 0 to High(FData) do
    FData[i] := 0;
  FCount := 0;
end;

function TBuckets.GetBits(Offset, Length: Cardinal): UInt32;
var
  byteIndex, byteOffset, rem: Cardinal;
  bitMask: UInt32;
begin
  byteIndex := Offset div 8;
  byteOffset := Offset mod 8;
  if byteOffset + Length > 8 then
  begin
    rem := 8 - byteOffset;
    Result := GetBits(Offset, rem) or (GetBits(Offset + rem, Length - rem) shl rem);
    Exit;
  end;
  bitMask := (1 shl Length) - 1;
  Result := (UInt32(FData[byteIndex]) and (bitMask shl byteOffset)) shr byteOffset;
end;

procedure TBuckets.SetBits(Offset, Length, Bits: UInt32);
var
  byteIndex, byteOffset, rem: Cardinal;
  bitMask: UInt32;
begin
  byteIndex := Offset div 8;
  byteOffset := Offset mod 8;
  if byteOffset + Length > 8 then
  begin
    rem := 8 - byteOffset;
    SetBits(Offset, rem, Bits);
    SetBits(Offset + rem, Length - rem, Bits shr rem);
    Exit;
  end;
  bitMask := (1 shl Length) - 1;
  FData[byteIndex] := Byte(UInt32(FData[byteIndex]) and not (bitMask shl byteOffset));
  FData[byteIndex] := Byte(UInt32(FData[byteIndex]) or ((Bits and bitMask) shl byteOffset));
end;

end.