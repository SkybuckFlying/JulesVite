{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/net/codec.go
}
unit V.Net.Codec;

interface

uses
  System.SysUtils, System.Classes, System.Net.Socket,
  V.Net.Message;

type
  ICodec = interface(IMsgReadWriter)
    ['{A1B2C3D4-E5F6-4A8B-9C8D-7E6F5A4B3C2D}']
    procedure Close;
    procedure SetReadTimeout(Timeout: TTimeSpan);
    procedure SetWriteTimeout(Timeout: TTimeSpan);
    procedure SetTimeout(Timeout: TTimeSpan);
    function Address: string;
  end;

  ICodecFactory = interface
    ['{B2C3D4E5-F6A7-4B8C-AD9E-8F706B5C4D3E}']
    function CreateCodec(Conn: TSocket): ICodec;
  end;

implementation

uses System.Net.Sockets, V.Snappy;

type
  TTransport = class(TInterfacedObject, ICodec)
  private
    FConn: TSocket;
    FReadTimeout: TTimeSpan;
    FWriteTimeout: TTimeSpan;
    FMinCompressLength: Integer;
    FReadHeadBuf: array[0..3] of Byte;
    FWriteHeadBuf: array[0..8] of Byte;
    FWriteBuf: TBytes;
    function IdLengthToBits(IdLength: Byte): Byte;
    function BitsToIdLength(Bits: Byte): Byte;
    function PutId(Id: TMsgId; var Buf: TBytes): Byte;
    procedure RetrieveMeta(Meta: Byte; out ISize, LSize: Byte; out Compressed: Boolean);
    function StoreMeta(ISize, LSize: Byte; Compressed: Boolean): Byte;
    function Varint(const Buf: TBytes): Cardinal;
    function PutVarint(var Buf: TBytes; N: Cardinal): Byte;
  public
    constructor Create(AConn: TSocket; AMinCompressLength: Integer; AReadTimeout, AWriteTimeout: TTimeSpan);
    destructor Destroy; override;
    function ReadMsg: TMsg;
    procedure WriteMsg(const Msg: TMsg);
    procedure Close;
    procedure SetReadTimeout(Timeout: TTimeSpan);
    procedure SetWriteTimeout(Timeout: TTimeSpan);
    procedure SetTimeout(Timeout: TTimeSpan);
    function Address: string;
  end;

  TTransportFactory = class(TInterfacedObject, ICodecFactory)
  private
    FMinCompressLength: Integer;
    FReadTimeout, FWriteTimeout: TTimeSpan;
  public
    constructor Create(AMinCompressLength: Integer; AReadTimeout, AWriteTimeout: TTimeSpan);
    function CreateCodec(Conn: TSocket): ICodec;
  end;

{ TTransport }

constructor TTransport.Create(AConn: TSocket; AMinCompressLength: Integer; AReadTimeout, AWriteTimeout: TTimeSpan);
begin
  inherited Create;
  FConn := AConn;
  FMinCompressLength := AMinCompressLength;
  FReadTimeout := AReadTimeout;
  FWriteTimeout := AWriteTimeout;
end;

destructor TTransport.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TTransport.ReadMsg: TMsg;
var
  isize, lsize: Byte;
  compressed: Boolean;
  len: Cardinal;
  payloadUncompressed: TBytes;
begin
  FConn.Receive(FReadHeadBuf, 2);
  RetrieveMeta(FReadHeadBuf[0], isize, lsize, compressed);
  Result.Code := FReadHeadBuf[1];

  if isize > 0 then
  begin
    FConn.Receive(FReadHeadBuf, isize);
    Result.Id := Varint(Copy(FReadHeadBuf, 0, isize));
  end;

  if lsize > 0 then
  begin
    FConn.Receive(FReadHeadBuf, lsize);
    len := Varint(Copy(FReadHeadBuf, 0, lsize));
    SetLength(Result.Payload, len);
    FConn.Receive(Result.Payload, len);
  end;

  if compressed then
  begin
    SetLength(payloadUncompressed, DecodedLen(Result.Payload));
    Result.Payload := Decode(payloadUncompressed, Result.Payload);
  end;
end;

procedure TTransport.WriteMsg(const Msg: TMsg);
var
  headLen, isize, lsize: Byte;
  compress: Boolean;
  payloadLen: Integer;
  payloadCompressed: TBytes;
  msgCopy: TMsg;
begin
  msgCopy := Msg;
  headLen := 2;
  FWriteHeadBuf[1] := msgCopy.Code;
  isize := PutId(msgCopy.Id, FWriteHeadBuf[2]);
  headLen := headLen + isize;

  compress := False;
  payloadLen := Length(msgCopy.Payload);
  if payloadLen > FMinCompressLength then
  begin
    payloadCompressed := Encode(nil, msgCopy.Payload);
    if Length(payloadCompressed) < payloadLen then
    begin
      msgCopy.Payload := payloadCompressed;
      payloadLen := Length(payloadCompressed);
      compress := True;
    end;
  end;

  lsize := PutVarint(FWriteHeadBuf[headLen], payloadLen);
  headLen := headLen + lsize;
  FWriteHeadBuf[0] := StoreMeta(isize, lsize, compress);
  FConn.Send(FWriteHeadBuf, headLen);
  FConn.Send(msgCopy.Payload, payloadLen);
end;

procedure TTransport.Close;
begin
  if Assigned(FConn) then
  begin
    FConn.Close;
    FConn := nil;
  end;
end;

procedure TTransport.SetReadTimeout(Timeout: TTimeSpan);
begin
  FReadTimeout := Timeout;
  FConn.ReceiveTimeout := Timeout.TotalMilliseconds;
end;

procedure TTransport.SetWriteTimeout(Timeout: TTimeSpan);
begin
  FWriteTimeout := Timeout;
  FConn.SendTimeout := Timeout.TotalMilliseconds;
end;

procedure TTransport.SetTimeout(Timeout: TTimeSpan);
begin
  SetReadTimeout(Timeout);
  SetWriteTimeout(Timeout);
end;

function TTransport.Address: string;
begin
  Result := FConn.RemoteAddress;
end;

function TTransport.IdLengthToBits(IdLength: Byte): Byte;
begin
  if IdLength = 4 then Result := 3 else Result := IdLength;
end;

function TTransport.BitsToIdLength(Bits: Byte): Byte;
begin
  if Bits = 3 then Result := 4 else Result := Bits;
end;

function TTransport.PutId(Id: TMsgId; var Buf: TBytes): Byte;
begin
  if Id = 0 then Exit(0);
  if Id > $FFFF then
  begin
    Buf[0] := Byte(Id shr 24); Buf[1] := Byte(Id shr 16);
    Buf[2] := Byte(Id shr 8); Buf[3] := Byte(Id);
    Result := 4;
  end
  else if Id > $FF then
  begin
    Buf[0] := Byte(Id shr 8); Buf[1] := Byte(Id);
    Result := 2;
  end
  else
  begin
    Buf[0] := Byte(Id);
    Result := 1;
  end;
end;

procedure TTransport.RetrieveMeta(Meta: Byte; out ISize, LSize: Byte; out Compressed: Boolean);
begin
  ISize := BitsToIdLength(Meta shr 6);
  LSize := (Meta shl 2) shr 6;
  Compressed := ((Meta shl 4) shr 7) > 0;
end;

function TTransport.StoreMeta(ISize, LSize: Byte; Compressed: Boolean): Byte;
begin
  Result := 0;
  Result := Result or (IdLengthToBits(ISize) shl 6);
  Result := Result or (LSize shl 4);
  if Compressed then Result := Result or 8;
end;

function TTransport.Varint(const Buf: TBytes): Cardinal;
var i, t: Integer;
begin
  Result := 0;
  t := Length(Buf);
  for i := 0 to t - 1 do
    Result := Result or (Cardinal(Buf[i]) shl ((t - i - 1) * 8));
end;

function TTransport.PutVarint(var Buf: TBytes; N: Cardinal): Byte;
var i: Byte;
begin
  Result := 0;
  if N = 0 then Exit;
  Result := 1;
  while (N shr (Result * 8)) > 0 do
    Inc(Result);
  for i := 0 to Result - 1 do
    Buf[i] := Byte(N shr ((Result - i - 1) * 8));
end;

{ TTransportFactory }
constructor TTransportFactory.Create(AMinCompressLength: Integer; AReadTimeout, AWriteTimeout: TTimeSpan);
begin
  inherited Create;
  FMinCompressLength := AMinCompressLength;
  FReadTimeout := AReadTimeout;
  FWriteTimeout := AWriteTimeout;
end;

function TTransportFactory.CreateCodec(Conn: TSocket): ICodec;
begin
  Result := TTransport.Create(Conn, FMinCompressLength, FReadTimeout, FWriteTimeout);
end;

end.