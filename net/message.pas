{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/net/message.go
}
unit V.Net.Message;

interface

uses
  System.SysUtils, System.Classes,
  V.Common.Types, V.Interfaces.Core, V.Net.Peer;

type
  TCode = Byte;
  TMsgId = UInt32;

const
  CodeDisconnect = 1;
  CodeHandshake = 2;
  CodeControlFlow = 3;
  CodeHeartBeat = 4;
  CodeGetHashList = 25;
  CodeHashList = 26;
  CodeGetSnapshotBlocks = 27;
  CodeSnapshotBlocks = 28;
  CodeGetAccountBlocks = 29;
  CodeAccountBlocks = 30;
  CodeNewSnapshotBlock = 31;
  CodeNewAccountBlock = 32;
  CodeSyncHandshake = 60;
  CodeSyncHandshakeOK = 61;
  CodeSyncRequest = 62;
  CodeSyncReady = 63;
  CodeException = 127;
  CodeTrace = 128;

type
  TMsg = record
    Code: TCode;
    Id: TMsgId;
    Payload: TBytes;
    ReceivedAt: Int64;
    Sender: TPeer; // Assuming TPeer will be defined in V.Net.Peer
  end;

  IMsgReader = interface
    ['{F0A1B2C3-D4E5-4F6A-B7C8-D9E0F1A2B3C4}']
    function ReadMsg: TMsg;
  end;

  IMsgWriter = interface
    ['{A1B2C3D4-E5F6-4A8B-9C8D-7E6F5A4B3C2D}']
    procedure WriteMsg(const Msg: TMsg);
  end;

  IMsgReadWriter = interface(IMsgReader, IMsgWriter)
    ['{B2C3D4E5-F6A7-4B8C-AD9E-8F706B5C4D3E}']
  end;

  IMsgWriteCloser = interface(IMsgWriter, IInterface)
    ['{C3D4E5F6-A7B8-4C9D-BEAF-90817C6D5E4F}']
    procedure Close;
  end;

  ISerializable = interface
    ['{D4E5F6A7-B8C9-4DAD-CFB0-A1928D7E6F5A}']
    function Serialize: TBytes;
    procedure Deserialize(const Buf: TBytes);
  end;

procedure Disconnect(const C: IMsgWriteCloser; const Err: Exception);

type
  // Message Structures
  TGetSnapshotBlocks = class(TInterfacedObject, ISerializable)
  public
    From: THashHeight;
    Count: UInt64;
    Forward: Boolean;
    function Serialize: TBytes;
    procedure Deserialize(const Buf: TBytes);
  end;

  TSnapshotBlocks = class(TInterfacedObject, ISerializable)
  public
    Blocks: array of PSnapshotBlock;
    function Serialize: TBytes;
    procedure Deserialize(const Buf: TBytes);
  end;

  TGetAccountBlocks = class(TInterfacedObject, ISerializable)
  public
    Address: TAddress;
    From: THashHeight;
    Count: UInt64;
    Forward: Boolean;
    function Serialize: TBytes;
    procedure Deserialize(const Buf: TBytes);
  end;

  TAccountBlocks = class(TInterfacedObject, ISerializable)
  public
    Blocks: array of PAccountBlock;
    TTL: Int32;
    function Serialize: TBytes;
    procedure Deserialize(const Buf: TBytes);
  end;

  TNewSnapshotBlock = class(TInterfacedObject, ISerializable)
  public
    Block: PSnapshotBlock;
    TTL: Int32;
    function Serialize: TBytes;
    procedure Deserialize(const Buf: TBytes);
  end;

  TNewAccountBlock = class(TInterfacedObject, ISerializable)
  public
    Block: PAccountBlock;
    TTL: Int32;
    function Serialize: TBytes;
    procedure Deserialize(const Buf: TBytes);
  end;

  THashHeightPoint = class
  public
    HashHeight: THashHeight;
    Size: UInt64;
  end;

  THashHeightPointList = class(TInterfacedObject, ISerializable)
  public
    Points: array of THashHeightPoint;
    function Serialize: TBytes;
    procedure Deserialize(const Buf: TBytes);
  end;

  TGetHashHeightList = class(TInterfacedObject, ISerializable)
  public
    From: array of THashHeight;
    Step: UInt64;
    To: UInt64;
    function Serialize: TBytes;
    procedure Deserialize(const Buf: TBytes);
  end;


implementation

uses V.Proto, V.Common.VitePB;

procedure Disconnect(const C: IMsgWriteCloser; const Err: Exception);
var
  Msg: TMsg;
  pe: TPeerError;
begin
  Msg.Code := CodeDisconnect;
  if Err is EPeerError then
  begin
    // This is a placeholder for actual serialization
    pe := TPeerError.Create;
    Msg.Payload := V.Proto.Marshal(pe);
  end;
  // Simplified error handling
  C.WriteMsg(Msg);
  C.Close;
end;

{ TGetSnapshotBlocks }
function TGetSnapshotBlocks.Serialize: TBytes;
var pb: TGetSnapshotBlocks;
begin
  pb := V.Common.VitePB.TGetSnapshotBlocks.Create;
  pb.From.Hash := Self.From.Hash;
  pb.From.Height := Self.From.Height;
  pb.Count := Self.Count;
  pb.Forward := Self.Forward;
  Result := V.Proto.Marshal(pb);
end;
procedure TGetSnapshotBlocks.Deserialize(const Buf: TBytes);
var pb: TGetSnapshotBlocks;
begin
  pb := V.Common.VitePB.TGetSnapshotBlocks.Create;
  V.Proto.Unmarshal(Buf, pb);
  Move(pb.From.Hash, Self.From.Hash, SizeOf(THash));
  Self.From.Height := pb.From.Height;
  Self.Count := pb.Count;
  Self.Forward := pb.Forward;
end;

{ TSnapshotBlocks }
function TSnapshotBlocks.Serialize: TBytes; begin Result := nil; end;
procedure TSnapshotBlocks.Deserialize(const Buf: TBytes); begin end;

{ TGetAccountBlocks }
function TGetAccountBlocks.Serialize: TBytes; begin Result := nil; end;
procedure TGetAccountBlocks.Deserialize(const Buf: TBytes); begin end;

{ TAccountBlocks }
function TAccountBlocks.Serialize: TBytes; begin Result := nil; end;
procedure TAccountBlocks.Deserialize(const Buf: TBytes); begin end;

{ TNewSnapshotBlock }
function TNewSnapshotBlock.Serialize: TBytes; begin Result := nil; end;
procedure TNewSnapshotBlock.Deserialize(const Buf: TBytes); begin end;

{ TNewAccountBlock }
function TNewAccountBlock.Serialize: TBytes; begin Result := nil; end;
procedure TNewAccountBlock.Deserialize(const Buf: TBytes); begin end;

{ THashHeightPointList }
function THashHeightPointList.Serialize: TBytes; begin Result := nil; end;
procedure THashHeightPointList.Deserialize(const Buf: TBytes); begin end;

{ TGetHashHeightList }
function TGetHashHeightList.Serialize: TBytes; begin Result := nil; end;
procedure TGetHashHeightList.Deserialize(const Buf: TBytes); begin end;


end.