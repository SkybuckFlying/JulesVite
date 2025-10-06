unit Go.LevelDB.MockDB;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Go.LevelDB,
  Go.LevelDB.Util;

type
  TMockIterator = class(TInterfacedObject, IIterator)
  private
    FDb: TDictionary<string, TBytes>;
    FKeys: TArray<string>;
    FCurrentIndex: Integer;
    FRange: IBytesPrefix;
  public
    constructor Create(db: TDictionary<string, TBytes>; range: IBytesPrefix);
    function Next: Boolean;
    function Key: TBytes;
    function Value: TBytes;
    function Error: Error;
    procedure Release;
  end;

  TMockDB = class(TInterfacedObject, ILevelDB)
  private
    FDb: TDictionary<string, TBytes>;
  public
    constructor Create;
    destructor Destroy; override;
    function Get(key: TBytes; ro: Pointer): TTuple<TBytes, Error>;
    function Put(key, value: TBytes; wo: Pointer): Error;
    function Delete(key: TBytes; wo: Pointer): Error;
    function NewIterator(slice: IBytesPrefix; ro: Pointer): IIterator;
  end;

function NewMockDB: ILevelDB;

implementation

uses
  System.Encoding;

{ TMockIterator }

constructor TMockIterator.Create(db: TDictionary<string, TBytes>; range: IBytesPrefix);
var
  key: string;
  start, limit: string;
begin
  FDb := db;
  FRange := range;
  FCurrentIndex := -1;

  start := TEncoding.ASCII.GetString(FRange.Start);
  limit := '';
  if FRange.Limit <> nil then
    limit := TEncoding.ASCII.GetString(FRange.Limit);

  FKeys := FDb.Keys.ToArray;
  TArray.Sort<string>(FKeys);

  var filteredKeys := TList<string>.Create;
  for key in FKeys do
  begin
    if (key >= start) and ((limit = '') or (key < limit)) then
      filteredKeys.Add(key);
  end;
  FKeys := filteredKeys.ToArray;
  filteredKeys.Free;
end;

function TMockIterator.Next: Boolean;
begin
  if FCurrentIndex < Length(FKeys) - 1 then
  begin
    Inc(FCurrentIndex);
    Result := True;
  end
  else
    Result := False;
end;

function TMockIterator.Key: TBytes;
begin
  Result := TEncoding.ASCII.GetBytes(FKeys[FCurrentIndex]);
end;

function TMockIterator.Value: TBytes;
begin
  Result := FDb[FKeys[FCurrentIndex]];
end;

function TMockIterator.Error: Error;
begin
  Result := nil;
end;

procedure TMockIterator.Release;
begin
  // No-op for mock
end;

{ TMockDB }

constructor TMockDB.Create;
begin
  FDb := TDictionary<string, TBytes>.Create;
end;

destructor TMockDB.Destroy;
begin
  FDb.Free;
  inherited;
end;

function TMockDB.Get(key: TBytes; ro: Pointer): TTuple<TBytes, Error>;
var
  sKey: string;
  value: TBytes;
begin
  sKey := TEncoding.ASCII.GetString(key);
  if FDb.TryGetValue(sKey, value) then
    Result := TTuple.Create(value, nil)
  else
    Result := TTuple.Create(nil, ErrNotFound);
end;

function TMockDB.Put(key, value: TBytes; wo: Pointer): Error;
var
  sKey: string;
begin
  sKey := TEncoding.ASCII.GetString(key);
  FDb.AddOrSetValue(sKey, value);
  Result := nil;
end;

function TMockDB.Delete(key: TBytes; wo: Pointer): Error;
var
  sKey: string;
begin
  sKey := TEncoding.ASCII.GetString(key);
  FDb.Remove(sKey);
  Result := nil;
end;

function TMockDB.NewIterator(slice: IBytesPrefix; ro: Pointer): IIterator;
begin
  Result := TMockIterator.Create(FDb, slice);
end;

function NewMockDB: ILevelDB;
begin
  Result := TMockDB.Create;
end;

end.