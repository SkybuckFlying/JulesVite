unit V.LRU;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  { Doubly-linked list node for the LRU cache }
  TLRUNode<TKey, TValue> = class
  public
    Key: TKey;
    Value: TValue;
    Prev, Next: TLRUNode<TKey, TValue>;
  end;

  { ILRUCache interface }
  ILRUCache<TKey, TValue> = interface
    ['{E7B5A3C1-D8E6-4F5A-8B4A-7A5D8D3C4B8B}']
    function Get(const Key: TKey): TValue;
    procedure Put(const Key: TKey; const Value: TValue);
    function Contains(const Key: TKey): Boolean;
    procedure Remove(const Key: TKey);
    function Count: Integer;
    function Size: Integer;
    procedure Clear;
    function GetValue(const Key: TKey): TValue;
    procedure SetValue(const Key: TKey; const Value: TValue);
    property Items[const Key: TKey]: TValue read GetValue write SetValue; default;
  end;

  { TLRUCache class - A generic LRU cache implementation }
  TLRUCache<TKey, TValue> = class(TInterfacedObject, ILRUCache<TKey, TValue>)
  private
    FDictionary: TDictionary<TKey, TLRUNode<TKey, TValue>>;
    FHead, FTail: TLRUNode<TKey, TValue>;
    FSize: Integer;
    procedure MoveToFront(Node: TLRUNode<TKey, TValue>);
    procedure RemoveNode(Node: TLRUNode<TKey, TValue>);
    function GetValue(const Key: TKey): TValue;
    procedure SetValue(const Key: TKey; const Value: TValue);
  public
    constructor Create(ASize: Integer);
    destructor Destroy; override;
    function Get(const Key: TKey): TValue;
    procedure Put(const Key: TKey; const Value: TValue);
    function Contains(const Key: TKey): Boolean;
    procedure Remove(const Key: TKey);
    function Count: Integer;
    function Size: Integer;
    procedure Clear;
  end;

function NewLRU(Size: Integer): TTuple<ILRUCache<TValue, TObject>, Error>;

implementation

{ TLRUCache }

constructor TLRUCache<TKey, TValue>.Create(ASize: Integer);
begin
  if ASize <= 0 then
    raise EArgumentException.Create('Size must be greater than 0');
  inherited Create;
  FSize := ASize;
  FDictionary := TDictionary<TKey, TLRUNode<TKey, TValue>>.Create;
  FHead := nil;
  FTail := nil;
end;

destructor TLRUCache<TKey, TValue>.Destroy;
begin
  Clear;
  FDictionary.Free;
  inherited Destroy;
end;

procedure TLRUCache<TKey, TValue>.MoveToFront(Node: TLRUNode<TKey, TValue>);
begin
  if Node = FHead then
    Exit; // Already at the front

  RemoveNode(Node);

  Node.Next := FHead;
  if FHead <> nil then
    FHead.Prev := Node;
  FHead := Node;
  Node.Prev := nil;

  if FTail = nil then
    FTail := FHead;
end;

procedure TLRUCache<TKey, TValue>.RemoveNode(Node: TLRUNode<TKey, TValue>);
begin
  if Node.Prev <> nil then
    Node.Prev.Next := Node.Next
  else
    FHead := Node.Next;

  if Node.Next <> nil then
    Node.Next.Prev := Node.Prev
  else
    FTail := Node.Prev;
end;

function TLRUCache<TKey, TValue>.Get(const Key: TKey): TValue;
var
  Node: TLRUNode<TKey, TValue>;
begin
  if FDictionary.TryGetValue(Key, Node) then
  begin
    MoveToFront(Node);
    Result := Node.Value;
  end
  else
    Result := Default(TValue);
end;

procedure TLRUCache<TKey, TValue>.Put(const Key: TKey; const Value: TValue);
var
  Node: TLRUNode<TKey, TValue>;
begin
  if FDictionary.TryGetValue(Key, Node) then
  begin
    Node.Value := Value;
    MoveToFront(Node);
  end
  else
  begin
    if FDictionary.Count >= FSize then
    begin
      // Evict least recently used (tail)
      FDictionary.Remove(FTail.Key);
      RemoveNode(FTail);
    end;

    Node := TLRUNode<TKey, TValue>.Create;
    Node.Key := Key;
    Node.Value := Value;
    FDictionary.Add(Key, Node);
    MoveToFront(Node); // This will add it to the front
  end;
end;

function TLRUCache<TKey, TValue>.GetValue(const Key: TKey): TValue;
begin
  Result := Get(Key);
end;

procedure TLRUCache<TKey, TValue>.SetValue(const Key: TKey; const Value: TValue);
begin
  Put(Key, Value);
end;

function TLRUCache<TKey, TValue>.Contains(const Key: TKey): Boolean;
begin
  Result := FDictionary.ContainsKey(Key);
end;

procedure TLRUCache<TKey, TValue>.Remove(const Key: TKey);
var
  Node: TLRUNode<TKey, TValue>;
begin
  if FDictionary.TryGetValue(Key, Node) then
  begin
    RemoveNode(Node);
    FDictionary.Remove(Key);
  end;
end;

function TLRUCache<TKey, TValue>.Count: Integer;
begin
  Result := FDictionary.Count;
end;

function TLRUCache<TKey, TValue>.Size: Integer;
begin
  Result := FSize;
end;

procedure TLRUCache<TKey, TValue>.Clear;
begin
  FDictionary.Clear;
  FHead := nil;
  FTail := nil;
end;

function NewLRU(Size: Integer): TTuple<ILRUCache<TValue, TObject>, Error>;
begin
  try
    Result := TTuple.Create(TLRUCache<TValue, TObject>.Create(Size) as ILRUCache<TValue, TObject>, nil);
  except
    on E: Exception do
      Result := TTuple.Create(nil, E);
  end;
end;

end.