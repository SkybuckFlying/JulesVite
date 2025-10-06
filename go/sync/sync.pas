unit Go.Sync;

interface

uses
  System.SysUtils,
  System.Threading,
  System.SyncObjs;

type
  TWaitGroup = class
  private
    FCountdown: TCountdownEvent;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(delta: Integer);
    procedure Done;
    procedure Wait;
  end;

  TMutex = class(System.SyncObjs.TMutex)
  end;

  TGo = class
  public
    class procedure Create(proc: TProc);
  end;

  // Go's `chan struct{}` is often used for signaling. TEvent is a good equivalent.
  PChan = ^TChan;
  TChan = TEvent;

function make(out ch: PChan): PChan; overload;
procedure close(ch: PChan); overload;
operator Implicit(a: PChan): THandle;

implementation

{ TWaitGroup }

constructor TWaitGroup.Create;
begin
  FCountdown := TCountdownEvent.Create(0);
end;

destructor TWaitGroup.Destroy;
begin
  FCountdown.Free;
  inherited;
end;

procedure TWaitGroup.Add(delta: Integer);
begin
  FCountdown.AddCount(delta);
end;

procedure TWaitGroup.Done;
begin
  FCountdown.Signal;
end;

procedure TWaitGroup.Wait;
begin
  FCountdown.Wait;
end;

{ TGo }

class procedure TGo.Create(proc: TProc);
begin
  TTask.Run(proc);
end;

{ chan helpers }

function make(out ch: PChan): PChan;
begin
  ch := PChan(TEvent.Create(nil, True, False, ''));
  Result := ch;
end;

procedure close(ch: PChan);
begin
  if ch <> nil then
  begin
    ch.SetEvent;
    // TEvent should be freed by its owner.
    // In Go, channels are garbage collected. Here, we assume manual memory management
    // or ARC will handle the TEvent object.
  end;
end;

operator Implicit(a: PChan): THandle;
begin
  Result := a.Handle;
end;

end.