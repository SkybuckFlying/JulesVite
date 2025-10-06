{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/common/bloom/bloom.go
}
unit V.Common.Bloom;

interface

uses
  System.SysUtils, V.Common.Bloom.Bucket, V.Hash.FNV;

type
  // TFilter implements a classic thread-safe Bloom filter.
  TFilter = class
  private
    FBuckets: array[0..1] of TBuckets;
    FHash: IHash64;
    FM: Cardinal;
    FK: Cardinal;
    FCritSect: TCriticalSection;
    function TestHashUnlocked(Lower, Upper: UInt32): Boolean;
    procedure AddHashUnlocked(Lower, Upper: UInt32);
  public
    constructor Create(N: Cardinal; FpRate: Double);
    destructor Destroy; override;
    function Test(const Data: TBytes): Boolean;
    procedure Add(const Data: TBytes);
    function TestAndAdd(const Data: TBytes): Boolean;
  end;

implementation

uses
  V.Common.Bloom.Util;

{ TFilter }

constructor TFilter.Create(N: Cardinal; FpRate: Double);
begin
  inherited Create;
  FM := OptimalM(N, FpRate);
  FK := OptimalK(FpRate);
  FBuckets[0] := TBuckets.Create(FM, 1);
  FBuckets[1] := TBuckets.Create(FM, 1);
  FHash := New64;
  FCritSect := TCriticalSection.Create;
end;

destructor TFilter.Destroy;
begin
  FBuckets[0].Free;
  FBuckets[1].Free;
  FCritSect.Free;
  inherited Destroy;
end;

function TFilter.Test(const Data: TBytes): Boolean;
var
  lower, upper: UInt32;
begin
  FCritSect.Enter;
  try
    HashInternal(Data, FHash, lower, upper);
    Result := TestHashUnlocked(lower, upper);
  finally
    FCritSect.Leave;
  end;
end;

function TFilter.TestHashUnlocked(Lower, Upper: UInt32): Boolean;
var
  bkt: TBuckets;
  i: Cardinal;
begin
  for bkt in FBuckets do
  begin
    Result := True;
    for i := 0 to FK - 1 do
    begin
      if bkt.Get((lower + upper * i) mod FM) = 0 then
      begin
        Result := False;
        Break;
      end;
    end;
    if Result then
      Exit;
  end;
  Result := False;
end;

procedure TFilter.Add(const Data: TBytes);
var
  lower, upper: UInt32;
begin
  FCritSect.Enter;
  try
    HashInternal(Data, FHash, lower, upper);
    AddHashUnlocked(lower, upper);
  finally
    FCritSect.Leave;
  end;
end;

procedure TFilter.AddHashUnlocked(Lower, Upper: UInt32);
var
  temp: TBuckets;
  i: Cardinal;
begin
  if FBuckets[0].FullRatio > 0.8 then
  begin
    temp := FBuckets[0];
    FBuckets[0] := FBuckets[1];
    FBuckets[1] := temp;
    FBuckets[0].Reset;
  end;

  for i := 0 to FK - 1 do
  begin
    FBuckets[0].Set((lower + upper * i) mod FM, 1);
  end;
end;

function TFilter.TestAndAdd(const Data: TBytes): Boolean;
var
  lower, upper: UInt32;
begin
  FCritSect.Enter;
  try
    HashInternal(Data, FHash, lower, upper);
    if TestHashUnlocked(lower, upper) then
    begin
      Result := True;
      Exit;
    end;
    AddHashUnlocked(lower, upper);
    Result := False;
  finally
    FCritSect.Leave;
  end;
end;

end.