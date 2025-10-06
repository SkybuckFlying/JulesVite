{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/net/sync_state.go
}
unit V.Net.SyncState;

interface

uses
  System.SysUtils;

type
  TSyncState = (ssInit, ssSyncing, ssDone, ssError, ssCancel);
  TSyncErrorCode = (seNoPeers, seStuck, seDownloadError);

  ESyncError = class(Exception)
  private
    FCode: TSyncErrorCode;
  public
    constructor Create(ACode: TSyncErrorCode);
    property Code: TSyncErrorCode read FCode;
  end;

  ISyncState = interface; // Forward declaration

  ISyncStateHost = interface
    ['{A1B2C3D4-E5F6-4A8B-9C8D-7E6F5A4B3C2D}']
    procedure SetState(AState: ISyncState);
  end;

  ISyncState = interface
    ['{B2C3D4E5-F6A7-4B8C-AD9E-8F706B5C4D3E}']
    function GetState: TSyncState;
    procedure Enter;
    procedure Sync;
    procedure Done;
    procedure Error(Reason: TSyncErrorCode);
    procedure Cancel;
  end;

  TBaseSyncState = class(TInterfacedObject, ISyncState)
  protected
    FHost: ISyncStateHost;
  public
    constructor Create(AHost: ISyncStateHost);
    virtual function GetState: TSyncState = 0;
    virtual procedure Enter;
    virtual procedure Sync;
    virtual procedure Done;
    virtual procedure Error(Reason: TSyncErrorCode);
    virtual procedure Cancel;
  end;

  TSyncStateInit = class(TBaseSyncState)
  public
    function GetState: TSyncState; override;
    procedure Sync; override;
    procedure Done; override;
    procedure Error(Reason: TSyncErrorCode); override;
    procedure Cancel; override;
  end;

  TSyncStateSyncing = class(TBaseSyncState)
  public
    function GetState: TSyncState; override;
    procedure Sync; override;
    procedure Done; override;
    procedure Error(Reason: TSyncErrorCode); override;
    procedure Cancel; override;
  end;

  TSyncStateDone = class(TBaseSyncState)
  public
    function GetState: TSyncState; override;
    procedure Sync; override;
  end;

  TSyncStateError = class(TBaseSyncState)
  public
    function GetState: TSyncState; override;
    procedure Sync; override;
    procedure Done; override;
    procedure Cancel; override;
  end;

  TSyncStateCancel = class(TBaseSyncState)
  public
    function GetState: TSyncState; override;
  end;

implementation

const
  SyncErrorStr: array[TSyncErrorCode] of string = (
    'no peers', 'stuck', 'download error'
  );

{ ESyncError }
constructor ESyncError.Create(ACode: TSyncErrorCode);
begin
  inherited Create(SyncErrorStr[ACode]);
  FCode := ACode;
end;

{ TBaseSyncState }
constructor TBaseSyncState.Create(AHost: ISyncStateHost);
begin
  inherited Create;
  FHost := AHost;
end;
procedure TBaseSyncState.Enter; begin end;
procedure TBaseSyncState.Sync; begin end;
procedure TBaseSyncState.Done; begin end;
procedure TBaseSyncState.Error(Reason: TSyncErrorCode); begin end;
procedure TBaseSyncState.Cancel; begin end;

{ TSyncStateInit }
function TSyncStateInit.GetState: TSyncState; begin Result := ssInit; end;
procedure TSyncStateInit.Sync; begin FHost.SetState(TSyncStateSyncing.Create(FHost)); end;
procedure TSyncStateInit.Done; begin FHost.SetState(TSyncStateDone.Create(FHost)); end;
procedure TSyncStateInit.Error(Reason: TSyncErrorCode); begin FHost.SetState(TSyncStateError.Create(FHost)); end;
procedure TSyncStateInit.Cancel; begin FHost.SetState(TSyncStateCancel.Create(FHost)); end;

{ TSyncStateSyncing }
function TSyncStateSyncing.GetState: TSyncState; begin Result := ssSyncing; end;
procedure TSyncStateSyncing.Sync; begin FHost.SetState(TSyncStateSyncing.Create(FHost)); end;
procedure TSyncStateSyncing.Done; begin FHost.SetState(TSyncStateDone.Create(FHost)); end;
procedure TSyncStateSyncing.Error(Reason: TSyncErrorCode); begin FHost.SetState(TSyncStateError.Create(FHost)); end;
procedure TSyncStateSyncing.Cancel; begin FHost.SetState(TSyncStateCancel.Create(FHost)); end;

{ TSyncStateDone }
function TSyncStateDone.GetState: TSyncState; begin Result := ssDone; end;
procedure TSyncStateDone.Sync; begin FHost.SetState(TSyncStateSyncing.Create(FHost)); end;

{ TSyncStateError }
function TSyncStateError.GetState: TSyncState; begin Result := ssError; end;
procedure TSyncStateError.Sync; begin FHost.SetState(TSyncStateSyncing.Create(FHost)); end;
procedure TSyncStateError.Done; begin FHost.SetState(TSyncStateDone.Create(FHost)); end;
procedure TSyncStateError.Cancel; begin FHost.SetState(TSyncStateCancel.Create(FHost)); end;

{ TSyncStateCancel }
function TSyncStateCancel.GetState: TSyncState; begin Result := ssCancel; end;

end.