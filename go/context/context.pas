unit Go.Context;

interface

uses
  System.SysUtils,
  System.Threading;

type
  TCancelFunc = reference to procedure;

  IContext = interface
    ['{B2C3D4E5-F6A7-4B8C-AD9E-8F706B5C4D3F}']
    function Done: THandle;
    function Err: Error;
    function Deadline: TDateTime;
    function Value(key: Pointer): Pointer;
  end;

  TContext = class
  private
    class var FBackground: IContext;
  public
    class function Background: IContext;
    class function WithCancel(parent: IContext): TTuple<IContext, TCancelFunc>;
  end;

implementation

type
  TEmptyCtx = class(TInterfacedObject, IContext)
  public
    function Done: THandle;
    function Err: Error;
    function Deadline: TDateTime;
    function Value(key: Pointer): Pointer;
  end;

  TCancelCtx = class(TInterfacedObject, IContext)
  private
    FParent: IContext;
    FDone: TEvent;
    FErr: Error;
    procedure ParentDone;
  public
    constructor Create(parent: IContext);
    destructor Destroy; override;
    function Done: THandle;
    function Err: Error;
    function Deadline: TDateTime;
    function Value(key: Pointer): Pointer;
    procedure Cancel(err: Error);
  end;

{ TEmptyCtx }

function TEmptyCtx.Deadline: TDateTime;
begin
  Result := 0;
end;

function TEmptyCtx.Done: THandle;
begin
  Result := 0;
end;

function TEmptyCtx.Err: Error;
begin
  Result := nil;
end;

function TEmptyCtx.Value(key: Pointer): Pointer;
begin
  Result := nil;
end;

{ TCancelCtx }

constructor TCancelCtx.Create(parent: IContext);
begin
  FParent := parent;
  FDone := TEvent.Create(nil, True, False, '');
  if FParent.Done <> 0 then
  begin
    TTask.Run(procedure
    begin
      ParentDone;
    end);
  end;
end;

destructor TCancelCtx.Destroy;
begin
  FDone.Free;
  inherited;
end;

procedure TCancelCtx.Cancel(err: Error);
begin
  FErr := err;
  FDone.SetEvent;
end;

function TCancelCtx.Deadline: TDateTime;
begin
  Result := FParent.Deadline;
end;

function TCancelCtx.Done: THandle;
begin
  Result := FDone.Handle;
end;

function TCancelCtx.Err: Error;
begin
  Result := FErr;
end;

procedure TCancelCtx.ParentDone;
begin
  WaitForSingleObject(FParent.Done, INFINITE);
  Cancel(EProgrammerException.Create('Parent context cancelled'));
end;

function TCancelCtx.Value(key: Pointer): Pointer;
begin
  Result := FParent.Value(key);
end;

{ TContext }

class function TContext.Background: IContext;
begin
  if FBackground = nil then
    FBackground := TEmptyCtx.Create;
  Result := FBackground;
end;

class function TContext.WithCancel(parent: IContext): TTuple<IContext, TCancelFunc>;
var
  ctx: TCancelCtx;
begin
  ctx := TCancelCtx.Create(parent);
  Result := TTuple.Create(ctx as IContext, procedure
    begin
      ctx.Cancel(EProgrammerException.Create('Context cancelled'));
    end);
end;

end.