{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/net/peer_error.go
}
unit V.Net.PeerError;

interface

uses
  System.SysUtils;

type
  TPeerErrorCode = (
    peNetworkError, peDifferentNetwork, peTooManyPeers, peTooManySameNetPeers,
    peTooManyInboundPeers, peAlreadyConnected, peIncompatibleVersion,
    peQuitting, peNotHandshakeMsg, peInvalidSignature, peConnectSelf,
    peUnknownMessage, peUnmarshalError, peNoPermission, peBanned,
    peDifferentGenesis, peInvalidBlock, peInvalidMessage, peResponseTimeout,
    peInvalidToken, peUnknownReason = 255
  );

  EPeerError = class(Exception)
  private
    FCode: TPeerErrorCode;
  public
    constructor Create(ACode: TPeerErrorCode);
    property Code: TPeerErrorCode read FCode;
  end;

  TExpCode = (
    expMissing, expUnsolicited, expUnauthorized, expServerError,
    expChunkNotMatch, expOther
  );

  EExpError = class(Exception)
  private
    FCode: TExpCode;
  public
    constructor Create(ACode: TExpCode);
    property Code: TExpCode read FCode;
  end;

implementation

const
  PeerErrStr: array[TPeerErrorCode] of string = (
    'network error', 'different network', 'too many peers',
    'too many peers in the same net', 'too many inbound peers',
    'already connected', 'incompatible version', 'client quitting',
    'not handshake message', 'invalid signature', 'connected to self',
    'unknown message code', 'message unmarshal error', 'no permission',
    'banned', 'different genesis', 'invalid block', 'invalid message',
    'response timeout', 'invalid token'
  );

  ExpErrStr: array[TExpCode] of string = (
    'missing resource', 'unsolicited request', 'unauthorized',
    'server error', 'chunk not match', 'other exception'
  );

{ EPeerError }

constructor EPeerError.Create(ACode: TPeerErrorCode);
var
  Msg: string;
begin
  if ACode = peUnknownReason then
    Msg := 'unknown reason'
  else if (Ord(ACode) >= Low(PeerErrStr)) and (Ord(ACode) <= High(PeerErrStr)) then
    Msg := PeerErrStr[ACode]
  else
    Msg := 'unknown error';
  inherited Create(Msg);
  FCode := ACode;
end;

{ EExpError }

constructor EExpError.Create(ACode: TExpCode);
var
  Msg: string;
begin
  if (Ord(ACode) >= Low(ExpErrStr)) and (Ord(ACode) <= High(ExpErrStr)) then
    Msg := ExpErrStr[ACode]
  else
    Msg := 'unknown exception';
  inherited Create(Msg);
  FCode := ACode;
end;

end.