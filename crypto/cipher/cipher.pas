{
  This unit is a temporary placeholder for the Go 'crypto/cipher' package.
  It provides a minimal implementation to allow the conversion of dependent units.
}
unit V.Crypto.Cipher;

interface

uses
  System.SysUtils, V.Crypto.AES;

type
  IStream = interface
    ['{EADF3E3B-2F29-4A8A-9A4E-6E35A57A4645}']
    procedure XORKeyStream(var Dst, Src: TBytes);
  end;

  IAEAD = interface
    ['{A0B5D9F3-F8D8-4C6A-9A2E-2A4B5498D32E}']
    function Seal(const Dst, Nonce, Plaintext, AdditionalData: TBytes): TBytes;
    function Open(const Dst, Nonce, Ciphertext, AdditionalData: TBytes): TBytes;
  end;

// NewCTR returns a Stream which encrypts/decrypts using the given Block in
// counter mode. The length of iv must be the same as the Block's block size.
function NewCTR(Block: TAESCipher; const IV: TBytes): IStream;

// NewGCM returns a new GCM AEAD.
function NewGCM(Block: TAESCipher): IAEAD;

implementation

type
  TStreamCipher = class(TInterfacedObject, IStream)
  public
    procedure XORKeyStream(var Dst, Src: TBytes);
  end;

  TAEADCipher = class(TInterfacedObject, IAEAD)
  public
    function Seal(const Dst, Nonce, Plaintext, AdditionalData: TBytes): TBytes;
    function Open(const Dst, Nonce, Ciphertext, AdditionalData: TBytes): TBytes;
  end;

procedure TStreamCipher.XORKeyStream(var Dst, Src: TBytes);
begin
  // Placeholder implementation
  if Length(Dst) < Length(Src) then
    SetLength(Dst, Length(Src));
  Move(Src[0], Dst[0], Length(Src));
end;

function TAEADCipher.Seal(const Dst, Nonce, Plaintext, AdditionalData: TBytes): TBytes;
begin
  // Placeholder implementation
  Result := Plaintext;
end;

function TAEADCipher.Open(const Dst, Nonce, Ciphertext, AdditionalData: TBytes): TBytes;
begin
  // Placeholder implementation
  Result := Ciphertext;
end;

function NewCTR(Block: TAESCipher; const IV: TBytes): IStream;
begin
  Result := TStreamCipher.Create;
end;

function NewGCM(Block: TAESCipher): IAEAD;
begin
  Result := TAEADCipher.Create;
end;

end.