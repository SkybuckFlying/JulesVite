{
  This unit is a temporary placeholder for the Go 'snappy' package.
  It provides a minimal implementation to allow the conversion of dependent units.
}
unit V.Snappy;

interface

uses
  System.SysUtils;

// Encode returns the compressed form of src.
function Encode(const Dst, Src: TBytes): TBytes;

// Decode returns the uncompressed form of src.
function Decode(const Dst, Src: TBytes): TBytes;

// DecodedLen returns the length of the decoded block.
function DecodedLen(const Src: TBytes): Integer;

// MaxEncodedLen returns the maximum length of a compressed block.
function MaxEncodedLen(SrcLen: Integer): Integer;

implementation

function Encode(const Dst, Src: TBytes): TBytes;
begin
  // Placeholder: just return the source for now
  Result := Src;
end;

function Decode(const Dst, Src: TBytes): TBytes;
begin
  // Placeholder: just return the source for now
  Result := Src;
end;

function DecodedLen(const Src: TBytes): Integer;
begin
  // Placeholder: assume no compression
  Result := Length(Src);
end;

function MaxEncodedLen(SrcLen: Integer): Integer;
begin
  // Placeholder
  Result := SrcLen;
end;

end.