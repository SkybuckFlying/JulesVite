{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/common/lock.go
}
unit V.Common.Lock;

interface

uses
  System.SysUtils;

type
  TNonBlockLock = record
  private
    FB: Integer;
  public
    function TryLock: Boolean;
    procedure Lock;
    function Unlock: Boolean;
  end;

implementation

uses
  System.Threading;

{ TNonBlockLock }

function TNonBlockLock.TryLock: Boolean;
begin
  Result := TInterlocked.CompareExchange(FB, 1, 0) = 0;
end;

procedure TNonBlockLock.Lock;
var
  i: Integer;
begin
  i := 0;
  while True do
  begin
    if TInterlocked.CompareExchange(FB, 1, 0) = 0 then
      Exit;

    Inc(i);
    if i > 2000 then
    begin
      TThread.Sleep(1);
      i := 0;
    end;
  end;
end;

function TNonBlockLock.Unlock: Boolean;
begin
  Result := TInterlocked.CompareExchange(FB, 0, 1) = 1;
end;

end.