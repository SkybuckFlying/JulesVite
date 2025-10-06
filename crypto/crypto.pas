{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/crypto/crypto.go
}
unit V.Crypto;

interface

uses
  System.SysUtils, V.Crypto.Ed25519;

const
  GCMAdditionData = 'vite';

type
  TBytes32 = array[0..31] of Byte;

// X25519ComputeSecret computes the shared secret using X25519.
function X25519ComputeSecret(const PrivateKey, PeersPublicKey: TBytes): TBytes;

// AesCTRXOR encrypts/decrypts using AES in CTR mode.
function AesCTRXOR(const Key, InText, IV: TBytes): TBytes;

// AesGCMEncrypt encrypts using AES in GCM mode.
procedure AesGCMEncrypt(const Key, InText: TBytes; out OutText, Nonce: TBytes);

// AesGCMDecrypt decrypts using AES in GCM mode.
function AesGCMDecrypt(const Key, CipherText, Nonce: TBytes): TBytes;

// GetEntropyCSPRNG returns n bytes of cryptographically secure random data.
function GetEntropyCSPRNG(N: Integer): TBytes;

// VerifySig verifies an Ed25519 signature.
function VerifySig(const PubKey: TPublicKey; const Message, SigData: TBytes): Boolean;

implementation

uses
  System.Classes,
  V.Crypto.Curve25519, V.Crypto.AES, V.Crypto.Cipher, V.Crypto.Rand;

function CheckType(var Key: TBytes32; const TypeToCheck: TBytes): Boolean;
begin
  if Length(TypeToCheck) <> 32 then
    Exit(False);
  Move(TypeToCheck[0], Key, 32);
  Result := True;
end;

function X25519ComputeSecret(const PrivateKey, PeersPublicKey: TBytes): TBytes;
var
  sec, pri, pub: TBytes32;
begin
  if not CheckType(pri, PrivateKey) then
    raise Exception.Create('unexpected type of private key');
  if not CheckType(pub, PeersPublicKey) then
    raise Exception.Create('unexpected type of peers public key');

  V.Crypto.Curve25519.ScalarMult(sec, pri, pub);
  SetLength(Result, 32);
  Move(sec, Result[0], 32);
end;

function AesCTRXOR(const Key, InText, IV: TBytes): TBytes;
var
  aesBlock: TAESCipher;
  stream: IStream;
begin
  aesBlock := V.Crypto.AES.NewCipher(Key);
  try
    stream := V.Crypto.Cipher.NewCTR(aesBlock, IV);
    stream.XORKeyStream(Result, InText);
  finally
    aesBlock.Free;
  end;
end;

procedure AesGCMEncrypt(const Key, InText: TBytes; out OutText, Nonce: TBytes);
var
  aesBlock: TAESCipher;
  stream: IAEAD;
  gcmAdditionDataBytes: TBytes;
begin
  aesBlock := V.Crypto.AES.NewCipher(Key);
  try
    stream := V.Crypto.Cipher.NewGCM(aesBlock);
    Nonce := GetEntropyCSPRNG(12);
    gcmAdditionDataBytes := TEncoding.UTF8.GetBytes(GCMAdditionData);
    OutText := stream.Seal(nil, Nonce, InText, gcmAdditionDataBytes);
  finally
    aesBlock.Free;
  end;
end;

function AesGCMDecrypt(const Key, CipherText, Nonce: TBytes): TBytes;
var
  aesBlock: TAESCipher;
  stream: IAEAD;
  gcmAdditionDataBytes: TBytes;
begin
  aesBlock := V.Crypto.AES.NewCipher(Key);
  try
    stream := V.Crypto.Cipher.NewGCM(aesBlock);
    gcmAdditionDataBytes := TEncoding.UTF8.GetBytes(GCMAdditionData);
    Result := stream.Open(nil, Nonce, CipherText, gcmAdditionDataBytes);
  except
    on E: Exception do
      Result := nil;
  end;
end;

function GetEntropyCSPRNG(N: Integer): TBytes;
begin
  SetLength(Result, N);
  V.Crypto.Rand.ReadFull(Result);
end;

function VerifySig(const PubKey: TPublicKey; const Message, SigData: TBytes): Boolean;
var
  sig: TSignature;
begin
  if Length(SigData) <> SignatureSize then
    Exit(False);
  Move(SigData[0], sig, SignatureSize);
  Result := V.Crypto.Ed25519.Verify(PubKey, Message, sig);
end;

end.