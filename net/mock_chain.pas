{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/net/mock_chain.go
}
unit V.Net.MockChain;

interface

uses
  System.SysUtils,
  V.Common.Types, V.Interfaces, V.Interfaces.Core, V.Net.Interface;

type
  TMockChain = class(TInterfacedObject, IChain)
  private
    FHeight: UInt64;
  public
    constructor Create(AHeight: UInt64);
    // ISnapshotBlockReader
    function GetSnapshotBlockByHeight(Height: UInt64): PSnapshotBlock;
    function GetSnapshotBlockByHash(const Hash: THash): PSnapshotBlock;
    function GetSnapshotBlocks(const BlockHash: THash; Higher: Boolean; Count: UInt64): TSnapshotChunkArray;
    function GetSnapshotBlocksByHeight(Height: UInt64; Higher: Boolean; Count: UInt64): TSnapshotChunkArray;
    // IAccountBlockReader
    function GetAccountBlockByHeight(const Addr: TAddress; Height: UInt64): PAccountBlock;
    function GetAccountBlockByHash(const BlockHash: THash): PAccountBlock;
    function GetAccountBlocks(const BlockHash: THash; Count: UInt64): TAccountBlockArray;
    function GetAccountBlocksByHeight(const Addr: TAddress; Height: UInt64; Count: UInt64): TAccountBlockArray;
    function GetConfirmedTimes(const BlockHash: THash): UInt64;
    // IChainReader
    function GetLatestSnapshotBlock: PSnapshotBlock;
    function GetGenesisSnapshotBlock: PSnapshotBlock;
    // ILedgerReaderProvider
    function GetLedgerReaderByHeight(StartHeight, EndHeight: UInt64): ILedgerReader;
    // ISyncCacher
    function GetSyncCache: ISyncCache;
  end;

implementation

{ TMockChain }

constructor TMockChain.Create(AHeight: UInt64);
begin
  inherited Create;
  FHeight := AHeight;
end;

function TMockChain.GetSnapshotBlockByHeight(Height: UInt64): PSnapshotBlock;
begin
  raise ENotImplemented.Create('Not implemented');
end;

function TMockChain.GetSnapshotBlockByHash(const Hash: THash): PSnapshotBlock;
begin
  raise ENotImplemented.Create('Not implemented');
end;

function TMockChain.GetSnapshotBlocks(const BlockHash: THash; Higher: Boolean; Count: UInt64): TSnapshotChunkArray;
begin
  raise ENotImplemented.Create('Not implemented');
end;

function TMockChain.GetSnapshotBlocksByHeight(Height: UInt64; Higher: Boolean; Count: UInt64): TSnapshotChunkArray;
begin
  raise ENotImplemented.Create('Not implemented');
end;

function TMockChain.GetAccountBlockByHeight(const Addr: TAddress; Height: UInt64): PAccountBlock;
begin
  raise ENotImplemented.Create('Not implemented');
end;

function TMockChain.GetAccountBlockByHash(const BlockHash: THash): PAccountBlock;
begin
  raise ENotImplemented.Create('Not implemented');
end;

function TMockChain.GetAccountBlocks(const BlockHash: THash; Count: UInt64): TAccountBlockArray;
begin
  raise ENotImplemented.Create('Not implemented');
end;

function TMockChain.GetAccountBlocksByHeight(const Addr: TAddress; Height: UInt64; Count: UInt64): TAccountBlockArray;
begin
  raise ENotImplemented.Create('Not implemented');
end;

function TMockChain.GetConfirmedTimes(const BlockHash: THash): UInt64;
begin
  raise ENotImplemented.Create('Not implemented');
end;

function TMockChain.GetLatestSnapshotBlock: PSnapshotBlock;
begin
  New(Result);
  Result.Hash := (1, 1, 1); // Simplified hash
  Result.Height := FHeight;
end;

function TMockChain.GetGenesisSnapshotBlock: PSnapshotBlock;
begin
  New(Result);
  Result.Hash := (1, 0, 0); // Simplified hash
  Result.Height := 1;
end;

function TMockChain.GetLedgerReaderByHeight(StartHeight, EndHeight: UInt64): ILedgerReader;
begin
  raise ENotImplemented.Create('Not implemented');
end;

function TMockChain.GetSyncCache: ISyncCache;
begin
  raise ENotImplemented.Create('Not implemented');
end;

end.