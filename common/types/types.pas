unit V.Common.Types;

interface

uses
  System.SysUtils;

type
  THash = record
  private
    FBytes: TBytes;
  public
    class function FromBytes(b: TBytes): THash; static;
    function Bytes: TBytes;
    procedure SetBytes(b: TBytes);
    function ToString: string;
    class function Zero: THash; static;
  end;

  TAddress = record
  private
    FBytes: TBytes;
  public
    class function FromBytes(b: TBytes): TAddress; static;
    function Bytes: TBytes;
    procedure SetBytes(b: TBytes);
    function ToString: string;
  end;
  PAddress = ^TAddress;

  TTokenTypeId = record
  private
    FBytes: TBytes;
  public
    function ToString: string;
  end;

  TGid = record
  private
    FBytes: TBytes;
  public
    function ToString: string;
  end;
  PGid = ^TGid;

  THashHeight = record
    Hash: THash;
    Height: UInt64;
  end;
  PHashHeight = ^THashHeight;

  TRegistration = record
    Name: string;
    BlockProducingAddress: TAddress;
    HisAddrList: TArray<TAddress>;
  end;
  PRegistration = ^TRegistration;

  TVoteInfo = record
    SbpName: string;
    VoteAddr: TAddress;
  end;
  PVoteInfo = ^TVoteInfo;

  TConsensusGroupInfo = record
    Gid: TGid;
    NodeCount: Integer;
    Interval: UInt64;
    PerCount: Integer;
    RandCount: Integer;
    RandRank: Integer;
    Repeat: UInt16;
    CountingTokenId: TTokenTypeId;
    RegisterConditionId: Integer;
    RegisterConditionParam: TBytes;
    VoteConditionId: Integer;
    VoteConditionParam: TBytes;
    Owner: TAddress;
    StakeAmount: Pointer; // Placeholder for *big.Int
    ExpirationHeight: UInt64;
  end;
  PConsensusGroupInfo = ^TConsensusGroupInfo;

  TAccountBlock = record
    AccountAddress: TAddress;
  end;
  PAccountBlock = ^TAccountBlock;
  TAccountBlockArray = TArray<PAccountBlock>;

  ISnapshotBlock = interface
    ['{A1B2C3D4-E5F6-4A8B-9C8D-7E6F5A4B3C2A}']
    function get_Hash: THash;
    function get_Height: UInt64;
    function get_Producer: TAddress;
    function get_Timestamp: TDateTime;
    function get_PrevHash: THash;
    function get_Seed: UInt64;
    function get_SeedHash: PHash;
    property Hash: THash read get_Hash;
    property Height: UInt64 read get_Height;
    property Producer: TAddress read get_Producer;
    property Timestamp: TDateTime read get_Timestamp;
    property PrevHash: THash read get_PrevHash;
    property Seed: UInt64 read get_Seed;
    property SeedHash: PHash read get_SeedHash;
  end;
  PSnapshotBlock = ISnapshotBlock;

  TSnapshotChunkArray = TArray<ISnapshotBlock>;

  TContractMeta = record
    Gid: TGid;
  end;
  PContractMeta = ^TContractMeta;

function BytesToAddress(b: TBytes): TAddress;
function HexToAddress(s: string): TAddress;
function BytesToHash(b: TBytes): THash;
function CreateTokenTypeId: TTokenTypeId;

var
  GID_DPoS: TGid;
  GID_Snapshot: TGid;

implementation

uses V.Common.HexUtil;

{ THash }

function THash.Bytes: TBytes;
begin
  Result := FBytes;
end;

class function THash.FromBytes(b: TBytes): THash;
begin
  SetLength(Result.FBytes, Length(b));
  System.Move(b[0], Result.FBytes[0], Length(b));
end;

procedure THash.SetBytes(b: TBytes);
begin
  FBytes := b;
end;

function THash.ToString: string;
begin
  Result := Encode(FBytes);
end;

class function THash.Zero: THash;
begin
  SetLength(Result.FBytes, 32);
end;

{ TAddress }

function TAddress.Bytes: TBytes;
begin
  Result := FBytes;
end;

class function TAddress.FromBytes(b: TBytes): TAddress;
begin
  SetLength(Result.FBytes, Length(b));
  System.Move(b[0], Result.FBytes[0], Length(b));
end;

procedure TAddress.SetBytes(b: TBytes);
begin
  FBytes := b;
end;

function TAddress.ToString: string;
begin
  Result := Encode(FBytes);
end;

{ TTokenTypeId }

function TTokenTypeId.ToString: string;
begin
  Result := Encode(FBytes);
end;

{ TGid }

function TGid.ToString: string;
begin
  Result := Encode(FBytes);
end;

function BytesToAddress(b: TBytes): TAddress;
begin
  Result.SetBytes(b);
end;

function HexToAddress(s: string): TAddress;
begin
  Result.SetBytes(Decode(s));
end;

function BytesToHash(b: TBytes): THash;
begin
  Result.SetBytes(b);
end;

function CreateTokenTypeId: TTokenTypeId;
begin
  // Placeholder
end;

initialization
  // Placeholder values
  SetLength(GID_DPoS.FBytes, 32);
  SetLength(GID_Snapshot.FBytes, 32);
  GID_Snapshot.FBytes[0] := 1;
end.

end.