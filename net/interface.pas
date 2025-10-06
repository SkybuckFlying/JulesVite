{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/net/interface.go
}
unit V.Net.Interface;

interface

uses
  System.SysUtils, System.Generics.Collections,
  V.Common.Types, V.Crypto.Ed25519, V.Interfaces, V.Interfaces.Core,
  V.Ledger.Consensus, V.Net.VNode;

type
  TBlockSource = (bsBroadcast, bsSync, bsFetch);
  TSyncState = (ssUnknown, ssSyncing, ssSynced);

  ISnapshotBlockReader = interface
    ['{B4A6A7F0-8B3C-4C1F-9B0F-3F0E6A2D7E5B}']
    function GetSnapshotBlockByHeight(Height: UInt64): PSnapshotBlock;
    function GetSnapshotBlockByHash(const Hash: THash): PSnapshotBlock;
    function GetSnapshotBlocks(const BlockHash: THash; Higher: Boolean; Count: UInt64): TSnapshotChunkArray;
    function GetSnapshotBlocksByHeight(Height: UInt64; Higher: Boolean; Count: UInt64): TSnapshotChunkArray;
  end;

  IAccountBlockReader = interface
    ['{C5B7B8F1-9C4D-4D2F-AB1F-4F1E7B3D8E6C}']
    function GetAccountBlockByHeight(const Addr: TAddress; Height: UInt64): PAccountBlock;
    function GetAccountBlockByHash(const BlockHash: THash): PAccountBlock;
    function GetAccountBlocks(const BlockHash: THash; Count: UInt64): TAccountBlockArray;
    function GetAccountBlocksByHeight(const Addr: TAddress; Height: UInt64; Count: UInt64): TAccountBlockArray;
    function GetConfirmedTimes(const BlockHash: THash): UInt64;
  end;

  ILedgerReaderProvider = interface
    ['{D6C8C9F2-AD5E-4E3F-BC2F-5F2E8C4D9F7D}']
    function GetLedgerReaderByHeight(StartHeight, EndHeight: UInt64): ILedgerReader;
  end;

  IChainReader = interface
    ['{E7D9DAF3-BE6F-4F4F-CD3F-6F3E9D5EAF8E}']
    function GetLatestSnapshotBlock: PSnapshotBlock;
    function GetGenesisSnapshotBlock: PSnapshotBlock;
  end;

  ISyncCacher = interface
    ['{F8EAEBF4-CF7F-4A5F-DE4F-7F4EAE6FBF9F}']
    function GetSyncCache: ISyncCache;
  end;

  ISyncChain = interface(ISyncCacher, IChainReader)
    ['{A9FBF0A5-D08F-4B6F-EF5F-8F5FBF7FC0A0}']
    function GetSnapshotBlockByHeight(Height: UInt64): PSnapshotBlock;
  end;

  IChain = interface(ISnapshotBlockReader, IAccountBlockReader, IChainReader, ILedgerReaderProvider, ISyncCacher)
    ['{B0AC01B6-D19F-4C7F-FF6F-9F6FC08F01B1}']
  end;

  IIrreversibleReader = interface
    ['{C1BD12C7-D2AF-4D8F-007F-AF7FD19F12C2}']
    function GetIrreversibleBlock: PSnapshotBlock;
  end;

  TProducersEventCallback = procedure(const Event: TProducersEvent);
  IConsensus = interface
    ['{D2CE23D8-D3BF-4E9F-118F-BF8FE2AF23D3}']
    procedure SubscribeProducers(const GID: TGID; const ID: string; Fn: TProducersEventCallback);
    procedure UnSubscribe(const GID: TGID; const ID: string);
    function API: IAPIReader;
  end;

  IVerifier = interface
    ['{E3DF34E9-D4CF-4FAF-229F-CF9FF3BE34E4}']
    procedure VerifyNetSnapshotBlock(Block: PSnapshotBlock);
    procedure VerifyNetAccountBlock(Block: PAccountBlock);
  end;

  TSnapshotBlockCallback = procedure(Block: PSnapshotBlock; Source: TBlockSource);
  TAccountBlockCallback = procedure(const Addr: TAddress; Block: PAccountBlock; Source: TBlockSource);
  TSyncStateCallback = procedure(State: TSyncState);

  TChunk = record
  private
    FSize: Int64;
  public
    SnapshotChunks: TSnapshotChunkArray;
    SnapshotRange: array[0..1] of PHashHeight;
    AccountRange: TDictionary<TAddress, array[0..1] of PHashHeight>;
    HashMap: TDictionary<THash, Boolean>;
    Source: TBlockSource;
    class function New(const Chunks: TSnapshotChunkArray; ASource: TBlockSource): TChunk; static;
    procedure AddSnapshotBlock(Block: PSnapshotBlock);
    procedure AddAccountBlock(Block: PAccountBlock);
    procedure Done;
  end;

  IChunkReader = interface
    ['{F4E045FA-D5DF-40BF-33AF-D0A0F4E045FB}']
    function Peek: TChunk;
    procedure Pop(const EndHash: THash);
  end;

  IBlockSubscriber = interface
    ['{A5F1560B-D6EF-41CF-44B0-E1B1A5F1560B}']
    function SubscribeAccountBlock(Fn: TAccountBlockCallback): Integer;
    procedure UnsubscribeAccountBlock(SubId: Integer);
    function SubscribeSnapshotBlock(Fn: TSnapshotBlockCallback): Integer;
    procedure UnsubscribeSnapshotBlock(SubId: Integer);
  end;

  ISyncStateSubscriber = interface
    ['{B602671C-D7FF-42DF-55C1-F2C2B602671C}']
    function SubscribeSyncStatus(Fn: TSyncStateCallback): Integer;
    procedure UnsubscribeSyncStatus(SubId: Integer);
    function SyncState: TSyncState;
  end;

  ISubscriber = interface(IBlockSubscriber, ISyncStateSubscriber)
    ['{C713782D-D800-43DF-66D2-03D3C713782D}']
  end;

  IBroadcaster = interface
    ['{D824893E-D910-44EF-77E3-14E4D824893E}']
    procedure BroadcastSnapshotBlock(Block: PSnapshotBlock);
    procedure BroadcastSnapshotBlocks(const Blocks: TSnapshotChunkArray);
    procedure BroadcastAccountBlock(Block: PAccountBlock);
    procedure BroadcastAccountBlocks(const Blocks: TAccountBlockArray);
  end;

  IFetcher = interface
    ['{E9359A4F-DA21-45FF-88F4-25F5E9359A4F}']
    procedure FetchSnapshotBlocks(const Start: THash; Count: UInt64);
    procedure FetchSnapshotBlocksWithHeight(const Hash: THash; Height, Count: UInt64);
    procedure FetchAccountBlocks(const Start: THash; Count: UInt64; Address: PAddress);
    procedure FetchAccountBlocksWithHeight(const Start: THash; Count: UInt64; Address: PAddress; SHeight: UInt64);
  end;

  TSyncStatus = record end; // Placeholder
  TSyncDetail = record end; // Placeholder

  ISyncer = interface(ISyncStateSubscriber, IChunkReader)
    ['{FA46AB50-DB32-4600-9905-3606FA46AB50}']
    function Status: TSyncStatus;
    function Detail: TSyncDetail;
  end;

  INet = interface(ISyncer, IFetcher, IBroadcaster, IBlockSubscriber)
    ['{0B57BC61-DC43-4710-A016-47170B57BC61}']
    procedure Start;
    procedure Stop;
    function Info: TNodeInfo;
    function Nodes: TNodeArray;
    function PeerCount: Integer;
    function PeerKey: TPrivateKey;
  end;

implementation

class function TChunk.New(const Chunks: TSnapshotChunkArray; ASource: TBlockSource): TChunk;
var
  chunk: TSnapshotChunk;
  block: PAccountBlock;
  rng: array[0..1] of PHashHeight;
begin
  if Length(Chunks) = 0 then Exit;
  Result.SnapshotChunks := Chunks;
  Result.SnapshotRange[0] := new THashHeight;
  Result.SnapshotRange[0].Hash := Chunks[0].SnapshotBlock.PrevHash;
  Result.SnapshotRange[0].Height := Chunks[0].SnapshotBlock.Height - 1;
  Result.SnapshotRange[1] := new THashHeight;
  Result.SnapshotRange[1].Hash := Chunks[High(Chunks)].SnapshotBlock.Hash;
  Result.SnapshotRange[1].Height := Chunks[High(Chunks)].SnapshotBlock.Height;
  Result.AccountRange := TDictionary<TAddress, array[0..1] of PHashHeight>.Create;
  Result.HashMap := TDictionary<THash, Boolean>.Create;
  Result.Source := ASource;
  Result.FSize := Length(Chunks);

  for chunk in Chunks do
  begin
    Result.HashMap.Add(chunk.SnapshotBlock.Hash, True);
    for block in chunk.AccountBlocks do
    begin
      Result.HashMap.Add(block.Hash, True);
      if Result.AccountRange.TryGetValue(block.AccountAddress, rng) then
      begin
        rng[1].Height := block.Height;
        rng[1].Hash := block.Hash;
      end
      else
      begin
        rng[0] := new THashHeight;
        rng[0].Height := block.Height - 1;
        rng[0].Hash := block.PrevHash;
        rng[1] := new THashHeight;
        rng[1].Height := block.Height;
        rng[1].Hash := block.Hash;
        Result.AccountRange.Add(block.AccountAddress, rng);
      end;
    end;
  end;
end;

procedure TChunk.AddSnapshotBlock(Block: PSnapshotBlock);
begin
  // Placeholder implementation
end;

procedure TChunk.AddAccountBlock(Block: PAccountBlock);
begin
  // Placeholder implementation
end;

procedure TChunk.Done;
begin
  // Placeholder implementation
end;

end.