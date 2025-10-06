{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/net/finder.go
}
unit V.Net.Finder;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  V.Common.Types, V.Crypto.Ed25519, V.Net.Database, V.Net.Discovery,
  V.Net.VNode, V.Net.Peer, V.Ledger.Consensus;

type
  IConnector = interface
    ['{C4D5E6F7-A8B9-4CAD-BEAF-90817C6D5E4F}']
    procedure ConnectNode(Node: PNode);
  end;

  TFinder = class(TInterfacedObject, IFinder)
  private
    FSelf: TAddress;
    FSelfIsSBP: Boolean;
    FDB: TDB;
    FCritSect: TRTLCriticalSection;
    FTargets: TDictionary<TAddress, PNode>;
    FSubId: Integer;
    FMinPeers: Integer;
    FStaticNodes: TNodeArray;
    FResolver: IDiscoveryResolver; // Assume an interface for resolver
    FPeers: TPeerSet;
    FConnector: IConnector;
    FConsensus: IConsensus;
    FDialing: TDictionary<TNodeID, Boolean>;
    FSBPs: TDictionary<TAddress, Int64>;
    FObservers: TDictionary<Integer, procedure(IsSBP: Boolean)>;
    FTerm: TEvent;
    FLoopThread: TThread;
    procedure Loop;
    procedure Dial(Node: PNode);
    procedure DoDial(Node: PNode);
    procedure ReceiveNode(Node: PNode);
    function Total: Integer;
    procedure ReceiveProducers(const Event: TProducersEvent);
  public
    constructor Create(ASelf: TAddress; APeers: TPeerSet; AMinPeers: Integer; AStaticNodes: array of string; ADB: TDB; AConnector: IConnector; AConsensus: IConsensus);
    destructor Destroy; override;
    procedure SetResolver(Resolver: IDiscoveryResolver);
    procedure Sub(Subscriber: ISubscriber);
    procedure UnSub(Subscriber: ISubscriber);
    procedure Start;
    procedure Stop;
    function IsSBP(const Addr: TAddress): Boolean;
    function SelfIsSBP: Boolean;
  end;

implementation

uses System.Threading;

{ TFinder }

constructor TFinder.Create(ASelf: TAddress; APeers: TPeerSet; AMinPeers: Integer; AStaticNodes: array of string; ADB: TDB; AConnector: IConnector; AConsensus: IConsensus);
var
  i: Integer;
  node: PNode;
begin
  inherited Create;
  FSelf := ASelf;
  FPeers := APeers;
  FMinPeers := AMinPeers;
  FDB := ADB;
  FConnector := AConnector;
  FConsensus := AConsensus;
  FTargets := TDictionary<TAddress, PNode>.Create;
  FDialing := TDictionary<TNodeID, Boolean>.Create;
  FSBPs := TDictionary<TAddress, Int64>.Create;
  FObservers := TDictionary<Integer, procedure(IsSBP: Boolean)>.Create;
  TRTLCriticalSection.Initialize(FCritSect);
  SetLength(FStaticNodes, Length(AStaticNodes));
  for i := 0 to High(AStaticNodes) do
  begin
    // node := V.Net.VNode.ParseNode(AStaticNodes[i]); // Placeholder
    FStaticNodes[i] := node;
  end;
  // FConsensus.SubscribeProducers(TConsensus.SNAPSHOT_GID, 'sbpn', ReceiveProducers); // Placeholder
end;

destructor TFinder.Destroy;
begin
  Stop;
  FTargets.Free;
  FDialing.Free;
  FSBPs.Free;
  FObservers.Free;
  TRTLCriticalSection.Destroy(FCritSect);
  inherited Destroy;
end;

procedure TFinder.Loop;
var
  checkTicker: TTimer; // Not ideal for threads, but a placeholder
  nodes: TNodeArray;
  n: PNode;
  t: PNode;
  total: Integer;
begin
  // This is a simplified version of the loop logic
  while not FTerm.WaitFor(5000) do
  begin
    TRTLCriticalSection.Enter(FCritSect);
    try
      for n in FStaticNodes do
        Dial(n);
      if FSelfIsSBP then
        for t in FTargets.Values do
          Dial(t);
    finally
      TRTLCriticalSection.Leave(FCritSect);
    end;
    if Assigned(FResolver) then
    begin
      total := Total;
      if total < FMinPeers then
      begin
        nodes := FResolver.GetNodes((FMinPeers - total) * 2);
        TRTLCriticalSection.Enter(FCritSect);
        try
          for n in nodes do
            Dial(n);
        finally
          TRTLCriticalSection.Leave(FCritSect);
        end;
      end;
    end;
  end;
end;

procedure TFinder.Start;
begin
  FTerm := TEvent.Create(nil, True, False, '');
  FLoopThread := TThread.CreateAnonymousThread(Loop);
  FLoopThread.Start;
end;

procedure TFinder.Stop;
begin
  if Assigned(FTerm) then
    FTerm.SetEvent;
  if Assigned(FLoopThread) then
  begin
    FLoopThread.WaitFor;
    FLoopThread := nil;
  end;
  if Assigned(FTerm) then
  begin
    FTerm.Free;
    FTerm := nil;
  end;
end;

// ... other TFinder methods ...

end.