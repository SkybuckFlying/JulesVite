{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/net/block_feed.go
}
unit V.Net.BlockFeed;

interface

uses
  System.SysUtils, System.Generics.Collections,
  V.Common.Types, V.Interfaces.Core, V.Net.Interface;

type
  IBlockNotifier = interface
    ['{A1B2C3D4-E5F6-4A8B-9C8D-7E6F5A4B3C2D}']
    procedure NotifySnapshotBlock(Block: PSnapshotBlock; Source: TBlockSource);
    procedure NotifyAccountBlock(Block: PAccountBlock; Source: TBlockSource);
  end;

  IChunkNotifier = interface
    ['{B2C3D4E5-F6A7-4B8C-AD9E-8F706B5C4D3E}']
    procedure NotifyChunks(const Chunks: TSnapshotChunkArray; Source: TBlockSource);
  end;

  IBlockFeeder = interface(IBlockSubscriber, IBlockNotifier)
    ['{C3D4E5F6-A7B8-4C9D-BEAF-90817C6D5E4F}']
  end;

  IBlockReceiver = interface
    ['{D4E5F6A7-B8C9-4DAD-CFB0-A1928D7E6F5A}']
    procedure ReceiveAccountBlock(Block: PAccountBlock; Source: TBlockSource);
    procedure ReceiveSnapshotBlock(Block: PSnapshotBlock; Source: TBlockSource);
  end;

  TBlockFeed = class(TInterfacedObject, IBlockFeeder)
  private
    FASubs: TDictionary<Integer, TAccountBlockCallback>;
    FBSubs: TDictionary<Integer, TSnapshotBlockCallback>;
    FCurrentId: Integer;
    FBlackBlocks: TDictionary<THash, Boolean>;
  public
    constructor Create(ABlackBlocks: TDictionary<THash, Boolean>);
    destructor Destroy; override;
    function SubscribeAccountBlock(Fn: TAccountBlockCallback): Integer;
    procedure UnsubscribeAccountBlock(SubId: Integer);
    function SubscribeSnapshotBlock(Fn: TSnapshotBlockCallback): Integer;
    procedure UnsubscribeSnapshotBlock(SubId: Integer);
    procedure NotifySnapshotBlock(Block: PSnapshotBlock; Source: TBlockSource);
    procedure NotifyAccountBlock(Block: PAccountBlock; Source: TBlockSource);
  end;

  TSafeBlockNotifier = class(TInterfacedObject, IBlockReceiver)
  private
    FBlockFeeder: IBlockNotifier;
    FVerifier: IVerifier;
  public
    constructor Create(ABlockFeeder: IBlockNotifier; AVerifier: IVerifier);
    procedure ReceiveAccountBlock(Block: PAccountBlock; Source: TBlockSource);
    procedure ReceiveSnapshotBlock(Block: PSnapshotBlock; Source: TBlockSource);
  end;

implementation

{ TBlockFeed }

constructor TBlockFeed.Create(ABlackBlocks: TDictionary<THash, Boolean>);
begin
  inherited Create;
  FASubs := TDictionary<Integer, TAccountBlockCallback>.Create;
  FBSubs := TDictionary<Integer, TSnapshotBlockCallback>.Create;
  if Assigned(ABlackBlocks) then
    FBlackBlocks := ABlackBlocks
  else
    FBlackBlocks := TDictionary<THash, Boolean>.Create;
end;

destructor TBlockFeed.Destroy;
begin
  FASubs.Free;
  FBSubs.Free;
  FBlackBlocks.Free;
  inherited Destroy;
end;

function TBlockFeed.SubscribeAccountBlock(Fn: TAccountBlockCallback): Integer;
begin
  Inc(FCurrentId);
  FASubs.Add(FCurrentId, Fn);
  Result := FCurrentId;
end;

procedure TBlockFeed.UnsubscribeAccountBlock(SubId: Integer);
begin
  FASubs.Remove(SubId);
end;

function TBlockFeed.SubscribeSnapshotBlock(Fn: TSnapshotBlockCallback): Integer;
begin
  Inc(FCurrentId);
  FBSubs.Add(FCurrentId, Fn);
  Result := FCurrentId;
end;

procedure TBlockFeed.UnsubscribeSnapshotBlock(SubId: Integer);
begin
  FBSubs.Remove(SubId);
end;

procedure TBlockFeed.NotifySnapshotBlock(Block: PSnapshotBlock; Source: TBlockSource);
var
  Fn: TSnapshotBlockCallback;
begin
  if FBlackBlocks.ContainsKey(Block.Hash) then
    Exit;
  for Fn in FBSubs.Values do
    if Assigned(Fn) then
      Fn(Block, Source);
end;

procedure TBlockFeed.NotifyAccountBlock(Block: PAccountBlock; Source: TBlockSource);
var
  Fn: TAccountBlockCallback;
begin
  if FBlackBlocks.ContainsKey(Block.Hash) then
    Exit;
  for Fn in FASubs.Values do
    if Assigned(Fn) then
      Fn(Block.AccountAddress, Block, Source);
end;

{ TSafeBlockNotifier }

constructor TSafeBlockNotifier.Create(ABlockFeeder: IBlockNotifier; AVerifier: IVerifier);
begin
  inherited Create;
  FBlockFeeder := ABlockFeeder;
  FVerifier := AVerifier;
end;

procedure TSafeBlockNotifier.ReceiveAccountBlock(Block: PAccountBlock; Source: TBlockSource);
begin
  FVerifier.VerifyNetAccountBlock(Block);
  FBlockFeeder.NotifyAccountBlock(Block, Source);
end;

procedure TSafeBlockNotifier.ReceiveSnapshotBlock(Block: PSnapshotBlock; Source: TBlockSource);
begin
  FVerifier.VerifyNetSnapshotBlock(Block);
  FBlockFeeder.NotifySnapshotBlock(Block, Source);
end;

end.