{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/net/handshaker.go
}
unit V.Net.Handshaker;

interface

uses
  System.SysUtils, System.Net.Socket,
  V.Common.Types, V.Crypto.Ed25519, V.Net.VNode, V.Net.Codec, V.Interfaces.Core,
  V.Net.Netool;

type
  THandshakeMsg = class
  public
    Version: Int64;
    NetID: Int64;
    Name: string;
    ID: TNodeID;
    Timestamp: Int64;
    Height: UInt64;
    Head: THash;
    Genesis: THash;
    Key: TPublicKey;
    Token: TBytes;
    FileAddress: TBytes;
    PublicAddress: TBytes;
    function Serialize: TBytes;
    procedure Deserialize(const Data: TBytes);
  end;

  THandshakeCallback = function(const C: ICodec; Flag: TPeerFlags; const Their: THandshakeMsg): Boolean;

  THandshaker = class
  private
    FVersion: Integer;
    FNetId: Integer;
    FName: string;
    FId: TNodeID;
    FGenesis: THash;
    FFileAddress: TBytes;
    FPublicAddress: TBytes;
    FPeerKey: TPrivateKey;
    FKey: TPrivateKey;
    FCodecFactory: ICodecFactory;
    FChain: IChainReader;
    FBlackList: IBlackList;
    FOnHandshaker: THandshakeCallback;
    function GetSecret(const TheirId: TNodeID): TBytes;
    function VerifyHandshake(const Their: THandshakeMsg; const Secret: TBytes): Boolean;
    function MakeHandshake(const Secret: TBytes): THandshakeMsg;
    procedure SendHandshake(const C: ICodec; const Our: THandshakeMsg; MsgId: TMsgId);
    function ReadHandshake(const C: ICodec; out Their: THandshakeMsg; out MsgId: TMsgId): Boolean;
    function DoHandshake(const C: ICodec; Flag: TPeerFlags; const Their: THandshakeMsg): Boolean;
  public
    constructor Create(AVersion, ANetId: Integer; const AName: string; const AId: TNodeID; const AGenesis: THash; const AFileAddress, APublicAddress: TBytes; const APeerKey, AKey: TPrivateKey; ACodecFactory: ICodecFactory; AChain: IChainReader; ABlackList: IBlackList; AOnHandshaker: THandshakeCallback);
    function ReceiveHandshake(Conn: TSocket; out C: ICodec; out Their: THandshakeMsg; out Superior: Boolean): Boolean;
    function InitiateHandshake(Conn: TSocket; const Id: TNodeID; out C: ICodec; out Their: THandshakeMsg; out Superior: Boolean): Boolean;
  end;

implementation

uses System.Classes, System.DateUtils, V.Proto, V.Common.VitePB, V.Crypto;

function XORBytes(A, B: TBytes): TBytes;
var
  i, len: Integer;
begin
  len := Min(Length(A), Length(B));
  SetLength(Result, len);
  for i := 0 to len - 1 do
    Result[i] := A[i] xor B[i];
end;

{ THandshakeMsg }

function THandshakeMsg.Serialize: TBytes;
var pb: TProtoHandshake; // Assuming TProtoHandshake exists in V.Common.VitePB
begin
  pb := TProtoHandshake.Create;
  // ... copy fields to pb ...
  Result := V.Proto.Marshal(pb);
end;

procedure THandshakeMsg.Deserialize(const Data: TBytes);
var pb: TProtoHandshake;
begin
  pb := TProtoHandshake.Create;
  V.Proto.Unmarshal(Data, pb);
  // ... copy fields from pb ...
end;

{ THandshaker }

constructor THandshaker.Create(AVersion, ANetId: Integer; const AName: string; const AId: TNodeID; const AGenesis: THash; const AFileAddress, APublicAddress: TBytes; const APeerKey, AKey: TPrivateKey; ACodecFactory: ICodecFactory; AChain: IChainReader; ABlackList: IBlackList; AOnHandshaker: THandshakeCallback);
begin
  inherited Create;
  FVersion := AVersion; FNetId := ANetId; FName := AName; FId := AId; FGenesis := AGenesis;
  FFileAddress := AFileAddress; FPublicAddress := APublicAddress; FPeerKey := APeerKey; FKey := AKey;
  FCodecFactory := ACodecFactory; FChain := AChain; FBlackList := ABlackList; FOnHandshaker := AOnHandshaker;
end;

function THandshaker.ReceiveHandshake(Conn: TSocket; out C: ICodec; out Their: THandshakeMsg; out Superior: Boolean): Boolean;
var
  msgId: TMsgId;
  secret: TBytes;
  our: THandshakeMsg;
begin
  C := FCodecFactory.CreateCodec(Conn);
  if not ReadHandshake(C, Their, msgId) then Exit(False);
  secret := GetSecret(Their.ID);
  if not VerifyHandshake(Their, secret) then Exit(False);
  if not DoHandshake(C, [pfInbound], Their) then Exit(False);
  if Assigned(FOnHandshaker) and not FOnHandshaker(C, [pfOutbound], Their) then Exit(False);
  our := MakeHandshake(secret);
  SendHandshake(C, our, msgId);
  Result := True;
end;

function THandshaker.InitiateHandshake(Conn: TSocket; const Id: TNodeID; out C: ICodec; out Their: THandshakeMsg; out Superior: Boolean): Boolean;
var
  secret: TBytes;
  our: THandshakeMsg;
  msgId: TMsgId;
begin
  C := FCodecFactory.CreateCodec(Conn);
  secret := GetSecret(Id);
  our := MakeHandshake(secret);
  SendHandshake(C, our, 0);
  if not ReadHandshake(C, Their, msgId) then Exit(False);
  if not VerifyHandshake(Their, secret) then Exit(False);
  if not DoHandshake(C, [pfOutbound], Their) then Exit(False);
  if Assigned(FOnHandshaker) and not FOnHandshaker(C, [pfOutbound], Their) then Exit(False);
  Result := True;
end;

function THandshaker.GetSecret(const TheirId: TNodeID): TBytes;
var
  pub, priv: TBytes;
begin
  pub := V.Crypto.Ed25519.PublicKeyToX25519(TheirId);
  priv := V.Crypto.Ed25519.PrivateKeyToX25519(FPeerKey);
  Result := V.Crypto.X25519ComputeSecret(priv, pub);
end;

function THandshaker.VerifyHandshake(const Their: THandshakeMsg; const Secret: TBytes): Boolean;
var
  t, hash, token: TBytes;
begin
  SetLength(t, 8);
  // PInt64(@t[0])^ := Their.Timestamp; // Endianess matters
  hash := V.Crypto.Hash.Hash256([t]);
  token := XORBytes(hash, Secret);
  if Length(Their.Key) > 0 then
    Result := V.Crypto.Ed25519.Verify(Their.Key, token, Their.Token)
  else
    Result := CompareMem(PByte(token), PByte(Their.Token), Length(token));
end;

function THandshaker.MakeHandshake(const Secret: TBytes): THandshakeMsg;
var
  latestBlock: PSnapshotBlock;
  t, hash: TBytes;
begin
  Result := THandshakeMsg.Create;
  latestBlock := FChain.GetLatestSnapshotBlock;
  Result.Version := FVersion;
  Result.NetID := FNetId;
  Result.Name := FName;
  Result.ID := FId;
  Result.Timestamp := Round(Now * 86400);
  Result.Height := latestBlock.Height;
  Result.Head := latestBlock.Hash;
  Result.Genesis := FGenesis;
  Result.FileAddress := FFileAddress;
  Result.PublicAddress := FPublicAddress;
  SetLength(t, 8);
  // PInt64(@t[0])^ := Result.Timestamp; // Endianess
  hash := V.Crypto.Hash.Hash256([t]);
  Result.Token := XORBytes(hash, Secret);
  if Length(FKey) > 0 then
  begin
    Result.Key := Copy(FKey, 32, 32);
    Result.Token := V.Crypto.Ed25519.Sign(FKey, Result.Token);
  end;
end;

procedure THandshaker.SendHandshake(const C: ICodec; const Our: THandshakeMsg; MsgId: TMsgId);
var
  data: TBytes;
  msg: TMsg;
begin
  data := Our.Serialize;
  msg.Code := CodeHandshake;
  msg.Id := MsgId;
  msg.Payload := data;
  C.WriteMsg(msg);
end;

function THandshaker.ReadHandshake(const C: ICodec; out Their: THandshakeMsg; out MsgId: TMsgId): Boolean;
var
  msg: TMsg;
begin
  msg := C.ReadMsg;
  MsgId := msg.Id;
  if msg.Code <> CodeHandshake then Exit(False);
  Their := THandshakeMsg.Create;
  Their.Deserialize(msg.Payload);
  Result := True;
end;

function THandshaker.DoHandshake(const C: ICodec; Flag: TPeerFlags; const Their: THandshakeMsg): Boolean;
begin
  if Their.NetID <> FNetId then Exit(False);
  if not CompareMem(@Their.Genesis, @FGenesis, SizeOf(THash)) then Exit(False);
  Result := True;
end;

end.