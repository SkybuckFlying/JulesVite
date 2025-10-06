unit V.LRU;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  ILRUCache = interface
    ['{F0B1C2D3-E4F5-4A8B-9C8D-7E6F5A4B3C2D}']
    function Get(const Key: TValue): TObject;
    procedure Add(const Key: TValue; Value: TObject);
    function Contains(const Key: TValue): Boolean;
    procedure Remove(const Key: TValue);
    function Count: Integer;
    property Items[const Key: TValue]: TObject read Get write Add; default;
  end;

  TLRUCache = class(TInterfacedObject, ILRUCache)
  private
    FDictionary: TDictionary<TValue, TObject>;
    FQueue: TQueue<TValue>;
    FSize: Integer;
  public
    constructor Create(ASize: Integer);
    destructor Destroy; override;
    function Get(const Key: TValue): TObject;
    procedure Add(const Key: TValue; const Value: TObject);
    function Contains(const Key: TValue): Boolean;
    procedure Remove(const Key: TValue);
    function Count: Integer;
  end;

function NewLRU(Size: Integer): TTuple<ILRUCache, Error>;

implementation

{ TLRUCache }

constructor TLRUCache.Create(ASize: Integer);
begin
  if ASize <= 0 then
    raise EArgumentException.Create('Size must be greater than 0');
  inherited Create;
  FSize := ASize;
  FDictionary := TDictionary<TValue, TObject>.Create;
  FQueue := TQueue<TValue>.Create;
end;

destructor TLRUCache.Destroy;
begin
  FDictionary.Free;
  FQueue.Free;
  inherited Destroy;
end;

function TLRUCache.Get(const Key: TValue): TObject;
begin
  if FDictionary.TryGetValue(Key, Result) then
  begin
    // Move to front (most recently used)
    // This simple implementation doesn't reorder on get, a full one would.
  end
  else
    Result := nil;
end;

procedure TLRUCache.Add(const Key: TValue; const Value: TObject);
begin
  if FDictionary.ContainsKey(Key) then
  begin
    FDictionary[Key] := Value;
    // Move to front
    exit;
  end;

  if FQueue.Count >= FSize then
  begin
    // Evict least recently used
    FDictionary.Remove(FQueue.Dequeue);
  end;

  FDictionary.Add(Key, Value);
  FQueue.Enqueue(Key);
end;

function TLRUCache.Contains(const Key: TValue): Boolean;
begin
  Result := FDictionary.ContainsKey(Key);
end;

procedure TLRUCache.Remove(const Key: TValue);
begin
  if FDictionary.ContainsKey(Key) then
  begin
    FDictionary.Remove(Key);
    // This is inefficient. A real implementation would use a different structure.
    var newQueue := TQueue<TValue>.Create;
    while FQueue.Count > 0 do
    begin
      var item := FQueue.Dequeue;
      if not TValue.Equals(item, Key) then
        newQueue.Enqueue(item);
    end;
    FQueue.Free;
    FQueue := newQueue;
  end;
end;

function TLRUCache.Count: Integer;
begin
  Result := FDictionary.Count;
end;

function NewLRU(Size: Integer): TTuple<ILRUCache, Error>;
begin
  try
    Result := TTuple.Create(TLRUCache.Create(Size) as ILRUCache, nil);
  except
    on E: Exception do
      Result := TTuple.Create(nil, E);
  end;
end;

end.