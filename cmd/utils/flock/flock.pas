unit V.Cmd.Utils.Flock;

interface

uses
  System.SysUtils;

type
  IFlock = interface
    ['{E5F6A7B8-C9D0-4E8F-9081-726D5E4F3013}']
    function TryLock: TTuple<Boolean, Error>;
    procedure Unlock;
  end;

function New(path: string): IFlock;

implementation

type
  TFlock = class(TInterfacedObject, IFlock)
  private
    FPath: string;
    FFileHandle: THandle;
  public
    constructor Create(path: string);
    destructor Destroy; override;
    function TryLock: TTuple<Boolean, Error>;
    procedure Unlock;
  end;

{ TFlock }

constructor TFlock.Create(path: string);
begin
  FPath := path;
  FFileHandle := THandle.Invalid;
end;

destructor TFlock.Destroy;
begin
  if FFileHandle <> THandle.Invalid then
    Unlock;
  inherited;
end;

function TFlock.TryLock: TTuple<Boolean, Error>;
begin
  try
    // This is a simplified placeholder. A real implementation would use
    // platform-specific file locking APIs (e.g., LockFileEx on Windows,
    // flock on Linux).
    FFileHandle := FileCreate(FPath);
    if FFileHandle = THandle.Invalid then
      Result := TTuple.Create(False, EProgrammerException.Create('Failed to create lock file'))
    else
      Result := TTuple.Create(True, nil);
  except
    on E: Exception do
      Result := TTuple.Create(False, E);
  end;
end;

procedure TFlock.Unlock;
begin
  if FFileHandle <> THandle.Invalid then
  begin
    FileClose(FFileHandle);
    FFileHandle := THandle.Invalid;
    DeleteFile(FPath);
  end;
end;

function New(path: string): IFlock;
begin
  Result := TFlock.Create(path);
end;

end.