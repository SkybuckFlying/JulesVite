{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/common/mock.go
}
unit V.Common.Mock;

interface

uses
  System.SysUtils, V.Common.Types;

function MockAddress(i: Integer): TAddress;
function MockHash(i: Integer): THash;
function MockHashBy(i1, i: Integer): THash;

implementation

uses
  System.ConvUtils;

function MockAddress(i: Integer): TAddress;
var
  Base: string;
  Bytes: TBytes;
begin
  Base := '0000000000000000000fff' + Format('%.6d', [i]) + 'fff00000000000';
  Bytes := HexToBytes(Base);
  Result := BytesToAddress(Bytes);
end;

function MockHash(i: Integer): THash;
var
  Base: string;
  Bytes: TBytes;
begin
  Base := '0000000000000000000000000000fff' + Format('%.6d', [i]) + 'fff000000000000000000000000';
  Bytes := HexToBytes(Base);
  Result := BytesToHash(Bytes);
end;

function MockHashBy(i1, i: Integer): THash;
var
  Base: string;
  Bytes: TBytes;
begin
  Base := Format('%.6d', [i1]) + '0000000000000000000000fff' + Format('%.6d', [i]) + 'fff000000000000000000000000';
  Bytes := HexToBytes(Base);
  Result := BytesToHash(Bytes);
end;

end.