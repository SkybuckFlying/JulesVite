{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/net/peer.go
}
unit V.Net.Peer;

interface

uses
  System.SysUtils, System.SyncObjs, System.Classes, System.Generics.Collections,
  V.Common.Types, V.Common.Bloom, V.Net.VNode, V.Net.Message;

type
  EPeerError = class(Exception);
  TPeerFlag = (pfInbound, pfOutbound, pfStatic);
  TPeerFlags = set of TPeerFlag;

  TPeerManager = interface
    ['{A2B3C4D5-E6F7-4A8B-9C8D-7E6F5A4B3C2D}']
    procedure UpdatePeer(const P: TObject; NewSuperior: Boolean); // TObject used as TPeer is a class
  end;

  IMsgHandler = interface
    ['{B3C4D5E6-F7A8-4B9C-ADAE-8F706B5C4D3E}']
    procedure Handle(const Msg: TMsg);
  end;

  TPeer = class
  private
    FCodec: ICodec; // Assuming ICodec is defined elsewhere
    FId: TNodeID;
    FName: string;
    FHeight: UInt64;
    FHead: THash;
    FVersion: Int64;
    FPublicAddress: string;
    FFileAddress: string;
    FCreateAt: Int64;
    FFlag: TPeerFlags;
    FSuperior: Boolean;
    FReliable: Integer;
    FRunning: Integer;
    FWritable: Integer;
    FWriting: Integer;
    FReadQueue: TThreadedQueue<TMsg>;
    FWriteQueue: TThreadedQueue<TMsg>;
    FErrChan: TThreadedQueue<Exception>;
    FManager: TPeerManager;
    FHandler: IMsgHandler;
    FKnownBlocks: TFilter;
    FPeers: TDictionary<TNodeID, Boolean>;
    FPeersMtx: TCriticalSection;
    FOnce: TOnce;
    FLog: TLogger; // from V.Log15
    procedure GoLoop(Proc: TThreadProc; ErrChan: TThreadedQueue<Exception>);
    procedure ReadLoop;
    procedure WriteLoop;
    procedure HandleLoop;
    procedure StopWrite(const Err: Exception);
    function CanWritable: Boolean;
  public
    constructor Create(ACodec: ICodec; ATheirHandshake: THandshakeMsg; APublicAddress, AFileAddress: string; ASuperior: Boolean; AFlag: TPeerFlags; AManager: TPeerManager; AHandler: IMsgHandler);
    destructor Destroy; override;
    function WriteMsg(const Msg: TMsg): Boolean;
    function Info: TPeerInfo;
    procedure Run;
    procedure Close(const Err: Exception);
    procedure Disconnect(const Err: Exception);
    procedure SetState(const AHead: THash; AHeight: UInt64);
    procedure SetSuperior(ASuperior: Boolean);
    procedure SetPeers(const APeers: array of TPeerConn; Patch: Boolean);
    function GetPeers: TDictionary<TNodeID, Boolean>;
    procedure Send(Code: TCode; Id: TMsgId; Data: ISerializable);
  end;

  TPeerSet = class
  private
    FPeers: TDictionary<TNodeID, TPeer>;
    FPeersMtx: TRTLCriticalSection;
    FSubs: TList<TChannel<TPeerEvent>>; // TChannel and TPeerEvent would need to be defined
  public
    constructor Create;
    destructor Destroy; override;
    function Has(const Id: TNodeID): Boolean;
    procedure Add(Peer: TPeer);
    function Remove(const Id: TNodeID): TPeer;
    function Get(const Id: TNodeID): TPeer;
    function Count: Integer;
    function AllPeers: TArray<TPeer>;
  end;

implementation

uses System.Threading, V.Log15, V.Net.Netool;

{ TPeer }

constructor TPeer.Create(ACodec: ICodec; ATheirHandshake: THandshakeMsg; APublicAddress, AFileAddress: string; ASuperior: Boolean; AFlag: TPeerFlags; AManager: TPeerManager; AHandler: IMsgHandler);
begin
  inherited Create;
  FCodec := ACodec;
  FId := ATheirHandshake.ID;
  FName := ATheirHandshake.Name;
  FHeight := ATheirHandshake.Height;
  FHead := ATheirHandshake.Head;
  FVersion := ATheirHandshake.Version;
  FPublicAddress := APublicAddress;
  FFileAddress := AFileAddress;
  FCreateAt := ATheirHandshake.Timestamp;
  FFlag := AFlag;
  FSuperior := ASuperior;
  FReliable := 0;
  FRunning := 0;
  FWritable := 1;
  FWriting := 0;
  FReadQueue := TThreadedQueue<TMsg>.Create;
  FWriteQueue := TThreadedQueue<TMsg>.Create;
  FErrChan := TThreadedQueue<Exception>.Create;
  FManager := AManager;
  FHandler := AHandler;
  FKnownBlocks := TFilter.Create(10000, 0.01); // Example values
  FPeers := TDictionary<TNodeID, Boolean>.Create;
  FPeersMtx := TCriticalSection.Create;
  FLog := V.Log15.GLog; // Simplified
end;

destructor TPeer.Destroy;
begin
  FKnownBlocks.Free;
  FPeers.Free;
  FPeersMtx.Free;
  FReadQueue.Free;
  FWriteQueue.Free;
  FErrChan.Free;
  inherited Destroy;
end;

procedure TPeer.GoLoop(Proc: TThreadProc; ErrChan: TThreadedQueue<Exception>);
begin
  TThread.CreateAnonymousThread(
    procedure
    var
      E: Exception;
    begin
      try
        Proc;
      except
        on E_: Exception do
          E := E_;
      end;
      ErrChan.PushItem(E);
    end).Start;
end;

procedure TPeer.ReadLoop;
var
  Msg: TMsg;
  E: Exception;
begin
  try
    while True do
    begin
      Msg := FCodec.ReadMsg; // Assuming ReadMsg raises exception on error
      Msg.ReceivedAt := Round(Now * 86400); // Unix timestamp
      Msg.Sender := Self;
      if Msg.Code = CodeDisconnect then
      begin
        if Length(Msg.Payload) > 0 then
          E := EPeerError.Create(Chr(Msg.Payload[0]))
        else
          E := EPeerError.Create('Unknown reason');
        raise E;
      end;
      FReadQueue.PushItem(Msg);
    end;
  except
    on E_: Exception do
      StopWrite(EPeerError.Create('Failed to read message: ' + E_.Message));
  end;
end;

procedure TPeer.WriteLoop;
var
  Msg: TMsg;
begin
  while FWriteQueue.PopItem(Msg) = wrSignaled do
  begin
    try
      FCodec.WriteMsg(Msg);
    except
      on E: Exception do
      begin
        StopWrite(EPeerError.CreateFmt('Failed to write msg %d: %s', [Msg.Code, E.Message]));
        Exit;
      end;
    end;
  end;
end;

procedure TPeer.HandleLoop;
var
  Msg: TMsg;
begin
  while FReadQueue.PopItem(Msg) = wrSignaled do
  begin
    try
      FHandler.Handle(Msg);
    except
      on E: Exception do
      begin
        FLog.Error(Format('Failed to handle msg %d: %s', [Msg.Code, E.Message]));
        Exit;
      end;
    end;
  end;
end;

function TPeer.CanWritable: Boolean;
begin
  Result := TInterlocked.Read(FWritable) = 1;
end;

procedure TPeer.StopWrite(const Err: Exception);
begin
  TInterlocked.Exchange(FWritable, 0);
  FLog.Error(Format('Stop write: %s', [Err.Message]));
end;

function TPeer.WriteMsg(const Msg: TMsg): Boolean;
begin
  if not CanWritable then
    raise EPeerError.Create('Peer is not writable');

  Result := FWriteQueue.PushItem(Msg) = wrSignaled;
end;

procedure TPeer.Run;
var
  E: Exception;
begin
  if TInterlocked.CompareExchange(FRunning, 1, 0) = 0 then
  begin
    GoLoop(ReadLoop, FErrChan);
    GoLoop(WriteLoop, FErrChan);
    GoLoop(HandleLoop, FErrChan);
    if FErrChan.PopItem(E) = wrSignaled then
      raise E;
  end
  else
    raise EPeerError.Create('Peer is already running');
end;

procedure TPeer.Close(const Err: Exception);
begin
  if TInterlocked.CompareExchange(FRunning, 0, 1) = 1 then
  begin
    FLog.Error('Closing peer: ' + Err.Message);
    if Err is EPeerError then
      WriteMsg(TMsg(Code: CodeDisconnect, Payload: TEncoding.UTF8.GetBytes(Err.Message)));
    TThread.Sleep(100);
    StopWrite(Err);
    // Wait for writing to finish
    FCodec.Close;
    // Wait for loops to finish
  end;
end;

// ... other TPeer methods ...

{ TPeerSet }

constructor TPeerSet.Create;
begin
  inherited Create;
  FPeers := TDictionary<TNodeID, TPeer>.Create;
  TRTLCriticalSection.Initialize(FPeersMtx);
  FSubs := TList<TChannel<TPeerEvent>>.Create;
end;

destructor TPeerSet.Destroy;
begin
  FPeers.Free;
  TRTLCriticalSection.Destroy(FPeersMtx);
  FSubs.Free;
  inherited Destroy;
end;

function TPeerSet.Has(const Id: TNodeID): Boolean;
begin
  TRTLCriticalSection.Enter(FPeersMtx);
  try
    Result := FPeers.ContainsKey(Id);
  finally
    TRTLCriticalSection.Leave(FPeersMtx);
  end;
end;

// ... other TPeerSet methods ...

initialization
  // Initialization code
finalization
  // Finalization code
end.