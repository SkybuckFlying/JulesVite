{
  This unit is a temporary placeholder for the Go 'crypto/rand' package.
  It provides a minimal implementation to allow the conversion of dependent units.
}
unit V.Crypto.Rand;

interface

uses
  System.SysUtils;

// ReadFull fills the buffer with cryptographically secure random bytes.
procedure ReadFull(var Buf: TBytes);

implementation

uses
  System.Net.SSL;

procedure ReadFull(var Buf: TBytes);
var
  i: Integer;
  len: Integer;
begin
  len := Length(Buf);
  if len = 0 then
    Exit;

  // Use the system's CSPRNG. Note that TSSLRandom is available on most platforms.
  // A more robust cross-platform solution might be needed for production.
  TSSLRandom.GetRandomBytes(Pointer(Buf)^, len);
end;

end.