unit V.Common.Bloom;

interface

uses
  System.SysUtils,
  V.Common.Bloom.Util,
  V.Common.Bloom.Bucket;

type
  TFilter = class
  private
    FBuckets: TArray<TBucket>;
    FHashFuncs: Integer;
  public
    constructor Create(buckets, hashFuncs: Integer);
    procedure Add(data: TBytes);
    function Contains(data: TBytes): Boolean;
  end;

function NewFilter(buckets, hashFuncs: Integer): TFilter;

implementation

{ TFilter }

constructor TFilter.Create(buckets, hashFuncs: Integer);
var
  i: Integer;
begin
  FHashFuncs := hashFuncs;
  SetLength(FBuckets, buckets);
  for i := 0 to buckets - 1 do
    SetLength(FBuckets[i], 8); // 64 bits per bucket
end;

procedure TFilter.Add(data: TBytes);
var
  hashes: TArray<UInt32>;
  h: UInt32;
  bucketIndex, bitIndex: Integer;
begin
  hashes := BaseHashes(data);
  for h in hashes do
  begin
    bucketIndex := h mod Length(FBuckets);
    bitIndex := (h shr 16) mod 64; // Example of deriving bit index
    FBuckets[bucketIndex][bitIndex div 8] := FBuckets[bucketIndex][bitIndex div 8] or (1 shl (bitIndex mod 8));
  end;
end;

function TFilter.Contains(data: TBytes): Boolean;
var
  hashes: TArray<UInt32>;
  h: UInt32;
  bucketIndex, bitIndex: Integer;
begin
  hashes := BaseHashes(data);
  for h in hashes do
  begin
    bucketIndex := h mod Length(FBuckets);
    bitIndex := (h shr 16) mod 64;
    if (FBuckets[bucketIndex][bitIndex div 8] and (1 shl (bitIndex mod 8))) = 0 then
    begin
      Result := False;
      Exit;
    end;
  end;
  Result := True;
end;

function NewFilter(buckets, hashFuncs: Integer): TFilter;
begin
  Result := TFilter.Create(buckets, hashFuncs);
end;

end.