{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/net/mock_codec.go
}
unit V.Net.MockCodec;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs,
  V.Net.Message, V.Net.Codec;

type
  TMockAddress = class
  private
    FName: string;
  public
    constructor Create(AName: string);
    function Network: string;
    function ToString: string;
  end;

  TMockCodec = class(TInterfacedObject, ICodec)
  private
    FName: string;
    FReadChan: TThreadedQueue<TMsg>;
    FWriteChan: TThreadedQueue<TMsg>;
    FReadTimeout: TTimeSpan;
    FWriteTimeout: TTimeSpan;
    FTerm: TEvent;
    FClosed: Integer;
    FWriting: Integer;
  public
    constructor Create(AName: string; AReadChan, AWriteChan: TThreadedQueue<TMsg>);
    destructor Destroy; override;
    function ReadMsg: TMsg;
    procedure WriteMsg(const Msg: TMsg);
    procedure Close;
    procedure SetReadTimeout(Timeout: TTimeSpan);
    procedure SetWriteTimeout(Timeout: TTimeSpan);
    procedure SetTimeout(Timeout: TTimeSpan);
    function Address: string;
  end;

procedure MockPipe(out C1, C2: ICodec);

implementation

uses System.Threading;

{ TMockAddress }
constructor TMockAddress.Create(AName: string);
begin
  inherited Create;
  FName := AName;
end;
function TMockAddress.Network: string; begin Result := 'mock codec'; end;
function TMockAddress.ToString: string; begin Result := 'mock codec ' + FName; end;

{ TMockCodec }
constructor TMockCodec.Create(AName: string; AReadChan, AWriteChan: TThreadedQueue<TMsg>);
begin
  inherited Create;
  FName := AName;
  FReadChan := AReadChan;
  FWriteChan := AWriteChan;
  FTerm := TEvent.Create(nil, True, False, '');
end;

destructor TMockCodec.Destroy;
begin
  Close;
  FTerm.Free;
  inherited Destroy;
end;

function TMockCodec.ReadMsg: TMsg;
var
  popResult: TWaitResult;
begin
  popResult := FReadChan.PopItem(Result, Cardinal(FReadTimeout.TotalMilliseconds));
  if popResult <> wrSignaled then
  begin
    if popResult = wrTimeout then
      raise ENetTimeout.Create('Read timeout')
    else
      raise EStreamError.Create('Read from closed mock codec');
  end;
end;

procedure TMockCodec.WriteMsg(const Msg: TMsg);
begin
  if TInterlocked.Read(FClosed) = 1 then
    raise EStreamError.Create('Mock codec ' + FName + ' closed');

  TInterlocked.Increment(FWriting);
  try
    if FWriteChan.PushItem(Msg, Cardinal(FWriteTimeout.TotalMilliseconds)) <> wrSignaled then
      raise ENetTimeout.Create('Write timeout');
  finally
    TInterlocked.Decrement(FWriting);
  end;
end;

procedure TMockCodec.Close;
begin
  if TInterlocked.CompareExchange(FClosed, 1, 0) = 0 then
  begin
    FTerm.SetEvent;
    while TInterlocked.Read(FWriting) > 0 do
      TThread.Sleep(10);
    // Clearing the queues, assuming TThreadedQueue does not have a Close method
    while FReadChan.PopItem(TMsg.default) <> wrTimeout do;
    while FWriteChan.PopItem(TMsg.default) <> wrTimeout do;
  end;
end;

procedure TMockCodec.SetReadTimeout(Timeout: TTimeSpan);
begin
  FReadTimeout := Timeout;
end;

procedure TMockCodec.SetWriteTimeout(Timeout: TTimeSpan);
begin
  FWriteTimeout := Timeout;
end;

procedure TMockCodec.SetTimeout(Timeout: TTimeSpan);
begin
  FReadTimeout := Timeout;
  FWriteTimeout := Timeout;
end;

function TMockCodec.Address: string;
var
  addr: TMockAddress;
begin
  addr := TMockAddress.Create(FName);
  try
    Result := addr.ToString;
  finally
    addr.Free;
  end;
end;

procedure MockPipe(out C1, C2: ICodec);
var
  chan1, chan2: TThreadedQueue<TMsg>;
begin
  chan1 := TThreadedQueue<TMsg>.Create;
  chan2 := TThreadedQueue<TMsg>.Create;
  C1 := TMockCodec.Create('mock1', chan1, chan2);
  C2 := TMockCodec.Create('mock2', chan2, chan1);
end;

end.