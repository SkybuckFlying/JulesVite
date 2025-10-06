unit V.Common.Lock;

interface

uses
  System.SysUtils,
  System.SyncObjs;

type
  TChainRollback = class
  private
    FMutex: TMutex;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Lock;
    procedure Unlock;
  end;

implementation

{ TChainRollback }

constructor TChainRollback.Create;
begin
  FMutex := TMutex.Create;
end;

destructor TChainRollback.Destroy;
begin
  FMutex.Free;
  inherited;
end;

procedure TChainRollback.Lock;
begin
  FMutex.Acquire;
end;

procedure TChainRollback.Unlock;
begin
  FMutex.Release;
end;

end.