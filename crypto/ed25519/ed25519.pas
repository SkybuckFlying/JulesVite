{
  Copyright 2016 The Go Authors. All rights reserved.
  Use of this source code is governed by a BSD-style
  license that can be found in the LICENSE file.

  This file is a translation of the original Go source file:
  https://github.com/golang/crypto/blob/master/ed25519/ed25519.go
}
unit V.Crypto.Ed25519;

interface

uses
  System.SysUtils, V.Crypto.Ed25519.Internal.Edwards25519;

const
  PublicKeySize = 32;
  PrivateKeySize = 64;
  SignatureSize = 64;
  X25519SkSize = 32;
  DummyMessage = 'vite is best';

type
  TPublicKey = TBytes32;
  TPrivateKey = TBytes64;
  TSignature = TBytes64;

procedure GenerateKey(out PublicKey: TPublicKey; out PrivateKey: TPrivateKey);
procedure GenerateKeyFromD(const D: TBytes32; out PublicKey: TPublicKey; out PrivateKey: TPrivateKey);
function Sign(const PrivateKey: TPrivateKey; const Message: TBytes): TSignature;
function Verify(const PublicKey: TPublicKey; const Message: TBytes; const Sig: TSignature): Boolean;
function VerifySig(const PublicKey: TPublicKey; const Message: TBytes; const Sig: TSignature): Boolean;
function PublicKeyToX25519(const PublicKey: TPublicKey): TBytes32;
function PrivateKeyToX25519(const PrivateKey: TPrivateKey): TBytes32;

implementation

uses
  System.Classes, System.ConvUtils,
  V.Crypto.Blake2b, V.Crypto.Rand;

procedure GenerateKeyFromD(const D: TBytes32; out PublicKey: TPublicKey; out PrivateKey: TPrivateKey);
var
  Digest: TBytes64;
  hBytes, publicKeyBytes: TBytes32;
  A: TExtendedGroupElement;
  i: Integer;
  dSlice: TBytes;
begin
  Move(D, PrivateKey, 32);

  SetLength(dSlice, 32);
  Move(D, dSlice[0], 32);
  Digest := TBlake2b.Sum512(dSlice);

  Digest[0] := Digest[0] and 248;
  Digest[31] := Digest[31] and 127;
  Digest[31] := Digest[31] or 64;

  Move(Digest, hBytes, 32);
  GeScalarMultBase(A, hBytes);
  ExtendedGroupElementToBytes(publicKeyBytes, A);

  Move(publicKeyBytes, PrivateKey[32], 32);
  PublicKey := publicKeyBytes;
end;

procedure GenerateKey(out PublicKey: TPublicKey; out PrivateKey: TPrivateKey);
var
  randDBytes: TBytes;
  randD: TBytes32;
begin
  SetLength(randDBytes, 32);
  V.Crypto.Rand.ReadFull(randDBytes);
  Move(randDBytes[0], randD, 32);
  GenerateKeyFromD(randD, PublicKey, PrivateKey);
end;

function Sign(const PrivateKey: TPrivateKey; const Message: TBytes): TSignature;
var
  h: TBlake2b;
  digest1, messageDigest, hramDigest: TBytes64;
  expandedSecretKey, messageDigestReduced, hramDigestReduced, s, encodedR: TBytes32;
  R: TExtendedGroupElement;
  privateKeySlice, digest1Suffix, publicKeySlice, encodedRSlice: TBytes;
begin
  h := TBlake2b.Create;
  try
    SetLength(privateKeySlice, 32);
    Move(PrivateKey[0], privateKeySlice[0], 32);
    h.Write(privateKeySlice);
    h.Sum(digest1);

    Move(digest1, expandedSecretKey, 32);
    expandedSecretKey[0] := expandedSecretKey[0] and 248;
    expandedSecretKey[31] := expandedSecretKey[31] and 63;
    expandedSecretKey[31] := expandedSecretKey[31] or 64;

    h.Reset;
    SetLength(digest1Suffix, 32);
    Move(digest1[32], digest1Suffix[0], 32);
    h.Write(digest1Suffix);
    h.Write(Message);
    h.Sum(messageDigest);

    ScReduce(messageDigestReduced, messageDigest);
    GeScalarMultBase(R, messageDigestReduced);
    ExtendedGroupElementToBytes(encodedR, R);

    h.Reset;
    SetLength(encodedRSlice, 32);
    Move(encodedR, encodedRSlice[0], 32);
    h.Write(encodedRSlice);

    SetLength(publicKeySlice, 32);
    Move(PrivateKey[32], publicKeySlice[0], 32);
    h.Write(publicKeySlice);
    h.Write(Message);
    h.Sum(hramDigest);

    ScReduce(hramDigestReduced, hramDigest);
    ScMulAdd(s, hramDigestReduced, expandedSecretKey, messageDigestReduced);

    Move(encodedR, Result, 32);
    Move(s, Result[32], 32);
  finally
    h.Free;
  end;
end;

function Verify(const PublicKey: TPublicKey; const Message: TBytes; const Sig: TSignature): Boolean;
var
  A: TExtendedGroupElement;
  h: TBlake2b;
  digest: TBytes64;
  hReduced, s, checkR: TBytes32;
  R: TProjectiveGroupElement;
  sigPrefix, publicKeySlice: TBytes;
begin
  if (Sig[63] and 224) <> 0 then
    Exit(False);

  if not ExtendedGroupElementFromBytes(A, PublicKey) then
    Exit(False);
  FeNeg(A.X, A.X);
  FeNeg(A.T, A.T);

  h := TBlake2b.Create;
  try
    SetLength(sigPrefix, 32);
    Move(Sig, sigPrefix[0], 32);
    h.Write(sigPrefix);

    SetLength(publicKeySlice, 32);
    Move(PublicKey, publicKeySlice[0], 32);
    h.Write(publicKeySlice);
    h.Write(Message);
    h.Sum(digest);

    ScReduce(hReduced, digest);
    Move(Sig[32], s, 32);

    if not ScMinimal(s) then
      Exit(False);

    GeDoubleScalarMultVartime(R, hReduced, A, s);
    ProjectiveGroupElementToBytes(checkR, R);
    Result := CompareMem(@Sig[0], @checkR[0], 32);
  finally
    h.Free;
  end;
end;

function VerifySig(const PublicKey: TPublicKey; const Message: TBytes; const Sig: TSignature): Boolean;
begin
  // This is a simplified version of the Go implementation, which returns detailed errors.
  // For this translation, it just wraps Verify.
  Result := Verify(PublicKey, Message, Sig);
end;

function PublicKeyToX25519(const PublicKey: TPublicKey): TBytes32;
var
  A: TExtendedGroupElement;
  x, one_minus_y: TFieldElement;
begin
  ExtendedGroupElementFromBytes(A, PublicKey);
  FeOne(one_minus_y);
  FeSub(one_minus_y, one_minus_y, A.Y);
  FeOne(x);
  FeAdd(x, x, A.Y);
  FeInvert(one_minus_y, one_minus_y);
  FeMul(x, x, one_minus_y);
  FeToBytes(Result, x);
end;

function PrivateKeyToX25519(const PrivateKey: TPrivateKey): TBytes32;
var
  digest: TBytes64;
  privateKeySlice: TBytes;
begin
  SetLength(privateKeySlice, 32);
  Move(PrivateKey[0], privateKeySlice[0], 32);
  digest := TBlake2b.Sum512(privateKeySlice);
  digest[0] := digest[0] and 248;
  digest[31] := digest[31] and 127;
  digest[31] := digest[31] or 64;
  Move(digest, Result, 32);
end;

end.