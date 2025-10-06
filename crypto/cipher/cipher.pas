unit V.Crypto.Cipher;

interface

uses
  System.SysUtils,
  V.Crypto.AES;

type
  IStream = interface
    ['{B2C3D4E5-F6A7-4B8C-AD9E-8F706B5C4D3E}']
    procedure XORKeyStream(dst, src: TBytes);
  end;

function NewCTR(block: IBlock; iv: TBytes): IStream;

implementation

type
  TCtrStream = class(TInterfacedObject, IStream)
  public
    procedure XORKeyStream(dst, src: TBytes);
  end;

{ TCtrStream }

procedure TCtrStream.XORKeyStream(dst, src: TBytes);
begin
  // Placeholder implementation for CTR mode
end;

function NewCTR(block: IBlock; iv: TBytes): IStream;
begin
  Result := TCtrStream.Create;
end;

end.