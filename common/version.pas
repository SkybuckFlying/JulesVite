{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/common/version.go
}
unit V.Common.Version;

interface

uses
  System.SysUtils;

type
  TVersion = record
  private
    FVersion: UInt64;
  public
    procedure Inc;
    function Val: UInt64;
  end;

implementation

{ TVersion }

procedure TVersion.Inc;
begin
  TInterlocked.Add(FVersion, 1);
end;

function TVersion.Val: UInt64;
begin
  Result := TInterlocked.Read(FVersion);
end;

end.