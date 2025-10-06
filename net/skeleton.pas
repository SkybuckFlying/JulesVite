{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/net/skeleton.go
}
unit V.Net.Skeleton;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  V.Common.Types, V.Interfaces.Core, V.Net.Message, V.Net.Peer;

type
  THashHeightNode = class
  private
    FHashHeight: THashHeightPoint;
    FPeers: TDictionary<TNodeID, TPeer>;
    FNodes: TDictionary<THash, THashHeightNode>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddBranch(const List: array of THashHeightPoint; Sender: TPeer);
    function BestBranch: TArray<THashHeightPoint>;
  end;

  TSkeleton = class
  private
    FChecking: Integer;
    FTree: THashHeightNode;
    FBlackBlocks: TDictionary<THash, Boolean>;
    FPeers: TPeerSet;
    FIdGen: TMsgId;
    FCritSect: TCriticalSection;
    FPending: TDictionary<TMsgId, TPeer>;
    FWaitGroup: TCountdownEvent;
    procedure GetHashList(P: TPeer; Msg: TGetHashHeightList);
    procedure GetHashListFailed(Id: TMsgId; Sender: TPeer; Err: Exception);
    procedure RemovePending(Id: TMsgId);
  public
    constructor Create(APeers: TPeerSet; AIdGen: TMsgId; ABlackBlocks: TDictionary<THash, Boolean>);
    destructor Destroy; override;
    function Construct(const Start: array of THashHeight; EndHeight: UInt64): TArray<THashHeightPoint>;
    procedure ReceiveHashList(const Msg: TMsg; Sender: TPeer);
    procedure Reset;
  end;

implementation

uses System.Threading;

{ THashHeightNode }

constructor THashHeightNode.Create;
begin
  inherited Create;
  FPeers := TDictionary<TNodeID, TPeer>.Create;
  FNodes := TDictionary<THash, THashHeightNode>.Create;
end;

destructor THashHeightNode.Destroy;
begin
  FPeers.Free;
  FNodes.Free;
  inherited Destroy;
end;

procedure THashHeightNode.AddBranch(const List: array of THashHeightPoint; Sender: TPeer);
var
  tree, subTree: THashHeightNode;
  h: THashHeightPoint;
  ok: Boolean;
begin
  tree := Self;
  for h in List do
  begin
    ok := tree.FNodes.TryGetValue(h.HashHeight.Hash, subTree);
    if ok then
    begin
      subTree.FPeers.AddOrSetValue(Sender.Id, Sender);
    end
    else
    begin
      subTree := THashHeightNode.Create;
      subTree.FHashHeight := h;
      subTree.FPeers.Add(Sender.Id, Sender);
      tree.FNodes.Add(h.HashHeight.Hash, subTree);
    end;
    tree := subTree;
  end;
end;

function THashHeightNode.BestBranch: TArray<THashHeightPoint>;
var
  tree, subTree: THashHeightNode;
  weight: Integer;
  node: THashHeightNode;
begin
  SetLength(Result, 0);
  tree := Self;
  subTree := nil;
  while True do
  begin
    if (tree = nil) or (tree.FNodes.Count = 0) then
      Exit;
    weight := 0;
    for node in tree.FNodes.Values do
    begin
      if node.FPeers.Count > weight then
      begin
        weight := node.FPeers.Count;
        subTree := node;
      end;
    end;
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := subTree.FHashHeight;
    tree := subTree;
  end;
end;

{ TSkeleton }

constructor TSkeleton.Create(APeers: TPeerSet; AIdGen: TMsgId; ABlackBlocks: TDictionary<THash, Boolean>);
begin
  inherited Create;
  FPeers := APeers;
  FIdGen := AIdGen;
  FPending := TDictionary<TMsgId, TPeer>.Create;
  FBlackBlocks := ABlackBlocks;
  FCritSect := TCriticalSection.Create;
end;

destructor TSkeleton.Destroy;
begin
  FPending.Free;
  FCritSect.Free;
  inherited Destroy;
end;

function TSkeleton.Construct(const Start: array of THashHeight; EndHeight: UInt64): TArray<THashHeightPoint>;
var
  peers: TArray<TPeer>;
  msg: TGetHashHeightList;
  p: TPeer;
begin
  if TInterlocked.CompareExchange(FChecking, 1, 0) <> 0 then
    Exit(nil);
  try
    FTree := THashHeightNode.Create;
    try
      peers := FPeers.AllPeers; // Simplified: should be PickReliable
      if Length(peers) > 0 then
      begin
        msg := TGetHashHeightList.Create;
        msg.From := Start;
        msg.Step := 100; // syncTaskSize
        msg.To_ := EndHeight;
        FWaitGroup := TCountdownEvent.Create(Length(peers));
        for p in peers do
          GetHashList(p, msg);
        FWaitGroup.Wait;
        FWaitGroup.Free;
        FCritSect.Enter;
        try
          Result := FTree.BestBranch;
        finally
          FCritSect.Leave;
        end;
      end;
    finally
      FTree.Free;
    end;
  finally
    TInterlocked.Exchange(FChecking, 0);
  end;
end;

procedure TSkeleton.GetHashList(P: TPeer; Msg: TGetHashHeightList);
var
  mid: TMsgId;
begin
  mid := TInterlocked.Increment(FIdGen);
  try
    P.Send(CodeGetHashList, mid, Msg);
    FCritSect.Enter;
    try
      FPending.Add(mid, P);
    finally
      FCritSect.Leave;
    end;
    TTask.Run(procedure
      begin
        TThread.Sleep(10000); // getHashHeightListTimeout
        GetHashListFailed(mid, P, ENetTimeout.Create('timeout'));
      end);
  except
    on E: Exception do
    begin
      FWaitGroup.Signal;
      // p.catch(E);
    end;
  end;
end;

procedure TSkeleton.GetHashListFailed(Id: TMsgId; Sender: TPeer; Err: Exception);
begin
  RemovePending(Id);
  // Log error
end;

procedure TSkeleton.ReceiveHashList(const Msg: TMsg; Sender: TPeer);
var
  hh: THashHeightPointList;
  p: THashHeightPoint;
begin
  if TInterlocked.Read(FChecking) = 1 then
  begin
    hh := THashHeightPointList.Create;
    hh.Deserialize(Msg.Payload);
    RemovePending(Msg.Id);
    if FBlackBlocks.Count > 0 then
    begin
      for p in hh.Points do
        if FBlackBlocks.ContainsKey(p.HashHeight.Hash) then
        begin
          // sender.setReliable(False);
          Exit;
        end;
    end;
    FCritSect.Enter;
    try
      FTree.AddBranch(hh.Points, Sender);
    finally
      FCritSect.Leave;
    end;
  end;
end;

procedure TSkeleton.RemovePending(Id: TMsgId);
begin
  FCritSect.Enter;
  try
    if FPending.ContainsKey(Id) then
    begin
      FPending.Remove(Id);
      FWaitGroup.Signal;
    end;
  finally
    FCritSect.Leave;
  end;
end;

procedure TSkeleton.Reset;
begin
  FCritSect.Enter;
  try
    FPending.Clear;
    FTree := THashHeightNode.Create;
  finally
    FCritSect.Leave;
  end;
end;

end.