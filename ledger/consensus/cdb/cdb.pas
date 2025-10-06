unit V.Ledger.Consensus.Cdb;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Go.Big,
  Go.LevelDB,
  V.Common.Types,
  V.Common.VitePB,
  ProtoBuf;

const
  IndexElectionResult = $00;
  IndexPointPeriod = $01;
  IndexPointHour = $02;
  IndexPointDay = $03;

type
  TAddrArr = TArray<TAddress>;

  TContent = class
  public
    ExpectedNum: UInt32;
    FactualNum: UInt32;
    function Copy: TContent;
    procedure Merge(c: TContent);
    function Rate: Int32;
    procedure AddNum(ExpectedNum, FactualNum: UInt32);
  end;

  TVoteContent = class
  public
    Details: TDictionary<string, IBigInt>;
    Total: IBigInt;
  end;

  TPoint = class
  public
    PrevHash: THash;
    Hash: THash;
    Sbps: TDictionary<TAddress, TContent>;
    Votes: TVoteContent;
    constructor Create;
    function Json: string;
    function Marshal: TBytes;
    procedure Unmarshal(buf: TBytes);
    function LeftAppend(p: TPoint): Error;
    function RightAppend(p: TPoint): Error;
    function IsEmpty: Boolean;
    class function NewEmptyPoint(proofHash: THash): TPoint;
  end;

  TConsensusDB = class
  private
    FDb: ILevelDB;
  public
    constructor Create(db: ILevelDB);
    function GetPointByHeight(prefix: Byte; height: UInt64): TTuple<TPoint, Error>;
    function DeletePointByHeight(prefix: Byte; height: UInt64): Error;
    function StorePointByHeight(prefix: Byte; height: UInt64; p: TPoint): Error;
    function GetElectionResultByHash(hash: THash): TTuple<TArray<TAddress>, Error>;
    function DeleteElectionResultByHash(hash: THash): Error;
    procedure StoreElectionResultByHash(hash: THash; addrArr: TArray<TAddress>);
    procedure Check;
  end;

function NewConsensusDB(db: ILevelDB): TConsensusDB;
function CreateElectionResultPrefixKey: TBytes;
function CreateElectionResultKey(hash: THash): TBytes;
function CreatePointKey(prefix: Byte; height: UInt64): TBytes;

implementation

uses
  System.JSON,
  System.Classes,
  Go.LevelDB.Util;

function BytesToAddrArr(byt: TBytes): TArray<TAddress>;
var
  size, i: Integer;
  addr: TAddress;
begin
  size := Length(byt) div SizeOf(TAddress);
  SetLength(Result, size);
  for i := 0 to size - 1 do
  begin
    addr := BytesToAddress(Copy(byt, i * SizeOf(TAddress), SizeOf(TAddress)));
    Result[i] := addr;
  end;
end;

function AddrArrToBytes(addrs: TArray<TAddress>): TBytes;
var
  i: Integer;
  stream: TBytesStream;
begin
  stream := TBytesStream.Create;
  try
    for i := 0 to High(addrs) do
      stream.Write(addrs[i].Bytes, Length(addrs[i].Bytes));
    Result := stream.Bytes;
  finally
    stream.Free;
  end;
end;

{ TContent }

procedure TContent.AddNum(ExpectedNum, FactualNum: UInt32);
begin
  Self.ExpectedNum := Self.ExpectedNum + ExpectedNum;
  Self.FactualNum := Self.FactualNum + FactualNum;
end;

function TContent.Copy: TContent;
begin
  Result := TContent.Create;
  Result.ExpectedNum := ExpectedNum;
  Result.FactualNum := FactualNum;
end;

procedure TContent.Merge(c: TContent);
begin
  ExpectedNum := ExpectedNum + c.ExpectedNum;
  FactualNum := FactualNum + c.FactualNum;
end;

function TContent.Rate: Int32;
var
  result: IBigInt;
begin
  if ExpectedNum = 0 then
    Exit(-1);
  if FactualNum = 0 then
    Exit(0);
  result := TBigInt.New.Div(TBigInt.New(FactualNum * 1000000), TBigInt.New(ExpectedNum));
  Result := result.Int64;
end;

{ TPoint }

constructor TPoint.Create;
begin
  Sbps := TDictionary<TAddress, TContent>.Create;
end;

function TPoint.IsEmpty: Boolean;
begin
  Result := Hash = PrevHash;
end;

function TPoint.Json: string;
begin
  Result := TJson.ObjectToJsonString(Self);
end;

function TPoint.LeftAppend(p: TPoint): Error;
begin
  if p.Hash <> PrevHash then
  begin
    Result := EProgrammerException.CreateFmt('hash[%s] and prev[%s] hash can''t match', [Hash.ToString, p.PrevHash.ToString]);
    Exit;
  end;

  PrevHash := p.PrevHash;
  // Sbps := MergeMap(Sbps, p.Sbps); // TODO: Implement MergeMap
  Result := nil;
end;

function TPoint.Marshal: TBytes;
var
  pb: TConsensusPoint;
  i: Integer;
  pair: TPair<TAddress, TContent>;
  c: TPointContent;
  votePair: TPair<string, IBigInt>;
  vc: TPointVoteContent;
begin
  pb := TConsensusPoint.Create;
  pb.Hash := Hash.Bytes;
  pb.PrevHash := PrevHash.Bytes;

  if Sbps.Count > 0 then
  begin
    SetLength(pb.Contents, Sbps.Count);
    i := 0;
    for pair in Sbps do
    begin
      c := TPointContent.Create;
      c.Address := pair.Key.Bytes;
      c.ENum := pair.Value.ExpectedNum;
      c.FNum := pair.Value.FactualNum;
      pb.Contents[i] := c;
      Inc(i);
    end;
  end;

  if Votes <> nil then
  begin
    SetLength(pb.Votes, Votes.Details.Count + 1);
    i := 0;
    vc := TPointVoteContent.Create;
    vc.VoteCnt := Votes.Total.Bytes;
    pb.Votes[i] := vc;
    Inc(i);
    for votePair in Votes.Details do
    begin
      vc := TPointVoteContent.Create;
      vc.Name := votePair.Key;
      vc.VoteCnt := votePair.Value.Bytes;
      pb.Votes[i] := vc;
      Inc(i);
    end;
  end;
  Result := TProtoBuf.Marshal(pb);
end;

class function TPoint.NewEmptyPoint(proofHash: THash): TPoint;
begin
  Result := TPoint.Create;
  Result.PrevHash := proofHash;
  Result.Hash := proofHash;
end;

function TPoint.RightAppend(p: TPoint): Error;
begin
  if Hash <> p.PrevHash then
  begin
    Result := EProgrammerException.CreateFmt('hash[%s] and prev[%s] hash can''t match', [Hash.ToString, p.PrevHash.ToString]);
    Exit;
  end;

  Hash := p.Hash;
  // Sbps := MergeMap(Sbps, p.Sbps); // TODO: Implement MergeMap
  Result := nil;
end;

procedure TPoint.Unmarshal(buf: TBytes);
var
  pb: TConsensusPoint;
  v: TPointContent;
  addr: TAddress;
  vote: TPointVoteContent;
begin
  pb := TConsensusPoint.Create;
  TProtoBuf.Unmarshal(buf, pb);

  if Length(pb.Hash) > 0 then
    Hash.SetBytes(pb.Hash);

  if Length(pb.PrevHash) > 0 then
    PrevHash.SetBytes(pb.PrevHash);

  Sbps.Clear;
  for v in pb.Contents do
  begin
    addr.SetBytes(v.Address);
    Sbps.Add(addr, TContent.Create);
    Sbps[addr].ExpectedNum := v.ENum;
    Sbps[addr].FactualNum := v.FNum;
  end;

  if Length(pb.Votes) > 0 then
  begin
    Votes := TVoteContent.Create;
    Votes.Details := TDictionary<string, IBigInt>.Create;
    Votes.Total := TBigInt.New.SetBytes(pb.Votes[0].VoteCnt);
    for vote in pb.Votes do
    begin
      if vote = pb.Votes[0] then
        Continue;
      Votes.Details.Add(vote.Name, TBigInt.New.SetBytes(vote.VoteCnt));
    end;
  end;
end;

{ TConsensusDB }

procedure TConsensusDB.Check;
var
  db: ILevelDB;
  key: TBytes;
  iter: IIterator;
  i: UInt64;
  bytes: TBytes;
  hash: THash;
begin
  db := FDb;
  key := CreateElectionResultPrefixKey;
  iter := db.NewIterator(TBytesPrefix.New(key), nil);
  i := 0;
  while iter.Next do
  begin
    bytes := iter.Key;
    hash := BytesToHash(Copy(bytes, 1, Length(bytes) - 1));
    // fmt.Println(hash) // Placeholder for logging
    Inc(i);
  end;
end;

constructor TConsensusDB.Create(db: ILevelDB);
begin
  FDb := db;
end;

function TConsensusDB.DeleteElectionResultByHash(hash: THash): Error;
var
  key: TBytes;
begin
  key := CreateElectionResultKey(hash);
  Result := FDb.Delete(key, nil);
end;

function TConsensusDB.DeletePointByHeight(prefix: Byte; height: UInt64): Error;
var
  key: TBytes;
begin
  key := CreatePointKey(prefix, height);
  Result := FDb.Delete(key, nil);
end;

function TConsensusDB.GetElectionResultByHash(hash: THash): TTuple<TArray<TAddress>, Error>;
var
  key, value: TBytes;
  err: Error;
  resultArr: TArray<TAddress>;
begin
  key := CreateElectionResultKey(hash);
  Tuple.Create(value, err) := FDb.Get(key, nil);

  if err <> nil then
  begin
    if err = ErrNotFound then
      Result := TTuple.Create(nil, nil)
    else
      Result := TTuple.Create(nil, err);
    Exit;
  end;

  try
    resultArr := BytesToAddrArr(value);
    Result := TTuple.Create(resultArr, nil);
  except
    on E: Exception do
      Result := TTuple.Create(nil, EProgrammerException.CreateFmt('parse fail. %s, %s', [E.Message, string(value)]));
  end;
end;

function TConsensusDB.GetPointByHeight(prefix: Byte; height: UInt64): TTuple<TPoint, Error>;
var
  key, value: TBytes;
  err: Error;
  resultPoint: TPoint;
begin
  key := CreatePointKey(prefix, height);
  Tuple.Create(value, err) := FDb.Get(key, nil);
  if err <> nil then
  begin
    if err = ErrNotFound then
      Result := TTuple.Create(nil, nil)
    else
      Result := TTuple.Create(nil, err);
    Exit;
  end;

  resultPoint := TPoint.Create;
  try
    resultPoint.Unmarshal(value);
    Result := TTuple.Create(resultPoint, nil);
  except
    on E: Exception do
      Result := TTuple.Create(nil, E);
  end;
end;

procedure TConsensusDB.StoreElectionResultByHash(hash: THash; addrArr: TArray<TAddress>);
var
  data, key: TBytes;
begin
  data := AddrArrToBytes(addrArr);
  key := CreateElectionResultKey(hash);
  FDb.Put(key, data, nil);
end;

function TConsensusDB.StorePointByHeight(prefix: Byte; height: UInt64; p: TPoint): Error;
var
  key, byt: TBytes;
begin
  key := CreatePointKey(prefix, height);
  byt := p.Marshal;
  Result := FDb.Put(key, byt, nil);
end;

function NewConsensusDB(db: ILevelDB): TConsensusDB;
begin
  Result := TConsensusDB.Create(db);
end;

function CreateElectionResultKey(hash: THash): TBytes;
begin
  SetLength(Result, 1 + SizeOf(THash));
  Result[0] := IndexElectionResult;
  Move(hash.Bytes[0], Result[1], SizeOf(THash));
end;

function CreateElectionResultPrefixKey: TBytes;
begin
  SetLength(Result, 1);
  Result[0] := IndexElectionResult;
end;

function CreatePointKey(prefix: Byte; height: UInt64): TBytes;
var
  heightBytes: TBytes;
begin
  SetLength(Result, 1 + 8);
  Result[0] := prefix;
  heightBytes := TBitConverter.GetBytes(height);
  if TBitConverter.IsLittleEndian then
    Reverse(heightBytes);
  Move(heightBytes[0], Result[1], 8);
end;

end.