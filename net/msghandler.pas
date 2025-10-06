{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/net/msghandler.go
}
unit V.Net.MsgHandler;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  V.Net.Message, V.Interfaces.Core, V.Log15;

type
  IMsgHandler = interface
    ['{A1B2C3D4-E5F6-4A8B-9C8D-7E6F5A4B3C2D}']
    function Name: string;
    function Codes: TArray<TCode>;
    procedure Handle(const Msg: TMsg);
  end;

  TMsgHandlers = class(TInterfacedObject, IMsgHandler)
  private
    FName: string;
    FHandlers: TDictionary<TCode, IMsgHandler>;
  public
    constructor Create(AName: string);
    destructor Destroy; override;
    function Name: string;
    function Codes: TArray<TCode>;
    procedure Handle(const Msg: TMsg);
    procedure Register(Handler: IMsgHandler);
    procedure Unregister(Handler: IMsgHandler);
  end;

  TQueryHandler = class(TInterfacedObject, IMsgHandler)
  private
    FMsgHandlers: TMsgHandlers;
    FCritSect: TCriticalSection;
    FQueue: TQueue<TMsg>;
    FTerm: TEvent;
    FLoopThread: TThread;
    FLog: TLogger;
    procedure Loop;
  public
    constructor Create(Chain: IChain);
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    function Name: string;
    function Codes: TArray<TCode>;
    procedure Handle(const Msg: TMsg);
  end;

implementation

uses System.Threading, V.Tools.List, V.Net.Peer, V.Monitor;

{ TMsgHandlers }
constructor TMsgHandlers.Create(AName: string);
begin
  inherited Create;
  FName := AName;
  FHandlers := TDictionary<TCode, IMsgHandler>.Create;
end;
destructor TMsgHandlers.Destroy;
begin
  FHandlers.Free;
  inherited Destroy;
end;
function TMsgHandlers.Name: string; begin Result := FName; end;
function TMsgHandlers.Codes: TArray<TCode>;
begin
  Result := FHandlers.Keys.ToArray;
end;
procedure TMsgHandlers.Handle(const Msg: TMsg);
var handler: IMsgHandler;
begin
  if FHandlers.TryGetValue(Msg.Code, handler) then
    handler.Handle(Msg);
end;
procedure TMsgHandlers.Register(Handler: IMsgHandler);
var code: TCode;
begin
  for code in Handler.Codes do
    FHandlers.Add(code, Handler);
end;
procedure TMsgHandlers.Unregister(Handler: IMsgHandler);
var code: TCode;
begin
  for code in Handler.Codes do
    FHandlers.Remove(code);
end;

{ TQueryHandler }
constructor TQueryHandler.Create(Chain: IChain);
begin
  inherited Create;
  FMsgHandlers := TMsgHandlers.Create('query');
  FCritSect := TCriticalSection.Create;
  FQueue := TQueue<TMsg>.Create;
  FLog := V.Log15.GLog;
  // Register handlers
  // FMsgHandlers.Register(TGetSnapshotBlocksHandler.Create(Chain));
  // FMsgHandlers.Register(TGetAccountBlocksHandler.Create(Chain));
  // FMsgHandlers.Register(TCheckHandler.Create(Chain));
end;
destructor TQueryHandler.Destroy;
begin
  Stop;
  FMsgHandlers := nil;
  FCritSect.Free;
  FQueue.Free;
  inherited Destroy;
end;

procedure TQueryHandler.Start;
begin
  FTerm := TEvent.Create(nil, True, False, '');
  FLoopThread := TThread.CreateAnonymousThread(Loop);
  FLoopThread.Start;
end;

procedure TQueryHandler.Stop;
begin
  if Assigned(FTerm) then FTerm.SetEvent;
  if Assigned(FLoopThread) then FLoopThread.WaitFor;
  if Assigned(FTerm) then FTerm.Free;
end;

procedure TQueryHandler.Loop;
var
  tasks: array of TMsg;
  index, count: Integer;
  msg: TMsg;
begin
  SetLength(tasks, 10);
  while not FTerm.WaitFor(10) do
  begin
    FCritSect.Enter;
    try
      count := Min(10, FQueue.Count);
      for index := 0 to count - 1 do
        tasks[index] := FQueue.Dequeue;
    finally
      FCritSect.Leave;
    end;
    if count > 0 then
    begin
      for index := 0 to count - 1 do
      begin
        msg := tasks[index];
        // Simplified error handling
        FMsgHandlers.Handle(msg);
      end;
    end;
  end;
end;

function TQueryHandler.Name: string; begin Result := FMsgHandlers.Name; end;
function TQueryHandler.Codes: TArray<TCode>; begin Result := FMsgHandlers.Codes; end;
procedure TQueryHandler.Handle(const Msg: TMsg);
begin
  FCritSect.Enter;
  try
    FQueue.Enqueue(Msg);
  finally
    FCritSect.Leave;
  end;
end;

end.