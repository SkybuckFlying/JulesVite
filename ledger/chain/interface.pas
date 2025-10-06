{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/ledger/chain/interface.go
}
unit V.Ledger.Chain.Interface;

interface

uses
  System.SysUtils, System.Generics.Collections, System.Classes,
  V.Common.Types, V.Interfaces, V.Interfaces.Core, V.Ledger.Chain.Block,
  V.Ledger.Chain.Flusher, V.Ledger.Chain.Index, V.Ledger.Chain.Plugins,
  V.Ledger.Chain.State, V.Ledger.Consensus.Core, V.VM.Contracts.Dex;

type
  IConsensus = interface
    ['{A1B2C3D4-E5F6-4A8B-9C8D-7E6F5A4B3C2D}']
    function VerifyAccountProducer(Block: PAccountBlock): Boolean;
    function SBPReader: ISBPStatReader;
    function VerifyABsProducer(const Abs: TDictionary<TGid, TAccountBlockArray>): TAccountBlockArray;
  end;

  IChain = interface
    ['{B2C3D4E5-F6A7-4B8C-AD9E-8F706B5C4D3E}']
    // Lifecycle
    procedure Init;
    procedure Start;
    procedure Stop;
    procedure Destroy;
    // Event Manager
    procedure Register(Listener: IEventListener);
    procedure UnRegister(Listener: IEventListener);
    // C(Create)
    procedure InsertAccountBlock(VmAccountBlocks: PVmAccountBlock);
    function InsertSnapshotBlock(SnapshotBlock: PSnapshotBlock): TAccountBlockArray;
    // D(Delete)
    function DeleteAccountBlocks(const Addr: TAddress; const ToHash: THash): TAccountBlockArray;
    function DeleteAccountBlocksToHeight(const Addr: TAddress; ToHeight: UInt64): TAccountBlockArray;
    function DeleteSnapshotBlocks(const ToHash: THash): TSnapshotChunkArray;
    function DeleteSnapshotBlocksToHeight(ToHeight: UInt64): TSnapshotChunkArray;
    // R(Retrieve)
    function IsGenesisAccountBlock(const Hash: THash): Boolean;
    function IsAccountBlockExisted(const Hash: THash): Boolean;
    function GetAccountBlockByHeight(const Addr: TAddress; Height: UInt64): PAccountBlock;
    function GetAccountBlockHashByHeight(const Addr: TAddress; Height: UInt64): PHash;
    function GetAccountBlockByHash(const BlockHash: THash): PAccountBlock;
    function GetReceiveAbBySendAb(const SendBlockHash: THash): PAccountBlock;
    function IsReceived(const SendBlockHash: THash): Boolean;
    function GetAccountBlocks(const BlockHash: THash; Count: UInt64): TAccountBlockArray;
    function GetCompleteBlockByHash(const BlockHash: THash): PAccountBlock;
    function GetAccountBlocksByHeight(const Addr: TAddress; Height: UInt64; Count: UInt64): TAccountBlockArray;
    function GetAccountBlocksByRange(const Addr: TAddress; Start, &End: UInt64): TAccountBlockArray;
    function GetCallDepth(const SendBlock: THash): Word;
    function IsSeedConfirmedNTimes(const BlockHash: THash; N: UInt64): Boolean;
    function GetConfirmedTimes(const BlockHash: THash): UInt64;
    function GetLatestAccountBlock(const Addr: TAddress): PAccountBlock;
    function GetLatestAccountHeight(const Addr: TAddress): UInt64;
    function IsGenesisSnapshotBlock(const Hash: THash): Boolean;
    function IsSnapshotBlockExisted(const Hash: THash): Boolean;
    function GetGenesisSnapshotBlock: PSnapshotBlock;
    function GetLatestSnapshotBlock: PSnapshotBlock;
    function GetSnapshotHeightByHash(const Hash: THash): UInt64;
    function GetSnapshotHeaderByHeight(Height: UInt64): PSnapshotBlock;
    function GetSnapshotHashByHeight(Height: UInt64): PHash;
    function GetSnapshotBlockByHeight(Height: UInt64): PSnapshotBlock;
    function GetSnapshotHeaderByHash(const Hash: THash): PSnapshotBlock;
    function GetSnapshotBlockByHash(const Hash: THash): PSnapshotBlock;
    function GetRangeSnapshotHeaders(const StartHash, EndHash: THash): TArray<PSnapshotBlock>;
    function GetRangeSnapshotBlocks(const StartHash, EndHash: THash): TArray<PSnapshotBlock>;
    function GetSnapshotHeaders(const BlockHash: THash; Higher: Boolean; Count: UInt64): TArray<PSnapshotBlock>;
    function GetSnapshotBlocks(const BlockHash: THash; Higher: Boolean; Count: UInt64): TArray<PSnapshotBlock>;
    function GetSnapshotHeadersByHeight(Height: UInt64; Higher: Boolean; Count: UInt64): TArray<PSnapshotBlock>;
    function GetSnapshotBlocksByHeight(Height: UInt64; Higher: Boolean; Count: UInt64): TArray<PSnapshotBlock>;
    function GetConfirmSnapshotHeaderByAbHash(const AbHash: THash): PSnapshotBlock;
    function GetConfirmSnapshotBlockByAbHash(const AbHash: THash): PSnapshotBlock;
    function GetSnapshotHeaderBeforeTime(Timestamp: TDateTime): PSnapshotBlock;
    function GetSnapshotHeadersAfterOrEqualTime(EndHashHeight: PHashHeight; StartTime: TDateTime; Producer: PAddress): TArray<PSnapshotBlock>;
    function GetLastUnpublishedSeedSnapshotHeader(const Producer: TAddress; BeforeTime: TDateTime): PSnapshotBlock;
    function GetRandomSeed(const SnapshotHash: THash; N: Integer): UInt64;
    function GetSnapshotBlockByContractMeta(const Addr: TAddress; const FromHash: THash): PSnapshotBlock;
    function GetSeedConfirmedSnapshotBlock(const Addr: TAddress; const FromHash: THash): PSnapshotBlock;
    function GetSeed(LimitSb: PSnapshotBlock; const FromHash: THash): UInt64;
    function GetSubLedger(StartHeight, EndHeight: UInt64): TSnapshotChunkArray;
    function GetSubLedgerAfterHeight(Height: UInt64): TSnapshotChunkArray;
    function GetAllUnconfirmedBlocks: TAccountBlockArray;
    function GetUnconfirmedBlocks(const Addr: TAddress): TAccountBlockArray;
    function GetContentNeedSnapshot: TSnapshotContent; // Assuming TSnapshotContent is defined
    function GetContentNeedSnapshotRange: TDictionary<TAddress, PHeightRange>; // Assuming PHeightRange is defined
    procedure IterateContracts(IterateFunc: TFunc<TAddress, PContractMeta, Boolean>); // Assuming PContractMeta is defined
    procedure IterateAccounts(IterateFunc: TFunc<TAddress, UInt64, Boolean>);
    function GetBalance(const Addr: TAddress; const TokenId: TTokenId): TBigInteger;
    function GetBalanceMap(const Addr: TAddress): TDictionary<TTokenId, TBigInteger>;
    function GetConfirmedBalanceList(const AddrList: TArray<TAddress>; const TokenId: TTokenId; const SbHash: THash): TDictionary<TAddress, TBigInteger>;
    function GetContractCode(const ContractAddr: TAddress): TBytes;
    function GetContractMeta(const ContractAddress: TAddress): PContractMeta;
    function GetContractMetaInSnapshot(const ContractAddress: TAddress; SnapshotHeight: UInt64): PContractMeta;
    function GetContractList(const Gid: TGid): TArray<TAddress>;
    function GetQuotaUnused(const Address: TAddress): UInt64;
    function GetGlobalQuota: TQuotaInfo; // Assuming TQuotaInfo is defined
    function GetQuotaUsedList(const Address: TAddress): TArray<TQuotaInfo>;
    function GetStorageIterator(const Address: TAddress; const Prefix: TBytes): IStorageIterator; // Assuming IStorageIterator is defined
    function GetValue(const Address: TAddress; const Key: TBytes): TBytes;
    function GetVmLogList(LogListHash: PHash): TVmLogList; // Assuming TVmLogList is defined
    function GetVMLogListByAddress(const Address: TAddress; Start, &End: UInt64; Id: PHash): TVmLogList;
    function GetRegisterList(const SnapshotHash: THash; const Gid: TGid): TArray<PRegistration>; // Assuming PRegistration is defined
    function GetAllRegisterList(const SnapshotHash: THash; const Gid: TGid): TArray<PRegistration>;
    function GetConsensusGroupList(const SnapshotHash: THash): TArray<PConsensusGroupInfo>; // Assuming PConsensusGroupInfo is defined
    function GetConsensusGroup(const SnapshotHash: THash; const Gid: TGid): PConsensusGroupInfo;
    function GetVoteList(const SnapshotHash: THash; const Gid: TGid): TArray<PVoteInfo>; // Assuming PVoteInfo is defined
    function GetStakeBeneficialAmount(const Addr: TAddress): TBigInteger;
    function GetStakeQuota(const Addr: TAddress; out Quota: TQuota): TBigInteger; // Assuming TQuota is defined
    function GetStakeQuotas(const AddrList: TArray<TAddress>): TDictionary<TAddress, TQuota>;
    function GetTokenInfoById(const TokenId: TTokenId): PTokenInfo; // Assuming PTokenInfo is defined
    function GetAllTokenInfo: TDictionary<TTokenId, PTokenInfo>;
    function CalVoteDetails(const Gid: TGid; Info: PGroupInfo; SnapshotBlock: THashHeight): TArray<IVoteDetails>; // Assuming PGroupInfo and IVoteDetails are defined
    function GetStakeListByPage(const SnapshotHash: THash; const LastKey: TBytes; Count: UInt64; out NextKey: TBytes): TArray<PStakeInfo>; // Assuming PStakeInfo is defined
    function GetDexFundsByPage(const SnapshotHash: THash; const LastAddress: TAddress; Count: Integer): TArray<PFund>;
    function GetDexStakeListByPage(const SnapshotHash: THash; const LastKey: TBytes; Count: Integer; out NextKey: TBytes): TArray<PDelegateStakeInfo>;
    function GetLedgerReaderByHeight(StartHeight, EndHeight: UInt64): ILedgerReader;
    function GetSyncCache: ISyncCache;
    function LoadOnRoadRange(const Gid: TGid; Fn: TLoadOnroadFn): Boolean; // Assuming TLoadOnroadFn is defined
    procedure DeleteOnRoad(const ToAddress: TAddress; const SendBlockHash: THash);
    function GetOnRoadBlocksByAddr(const Addr: TAddress; PageNum, PageSize: Integer): TAccountBlockArray;
    function LoadAllOnRoad(out Map: TDictionary<TAddress, TArray<THash>>): Boolean;
    function GetAccountOnRoadInfo(const Addr: TAddress): PAccountInfo; // Assuming PAccountInfo is defined
    function GetOnRoadInfoUnconfirmedHashList(const Addr: TAddress): TArray<PHash>;
    procedure UpdateOnRoadInfo(const Addr: TAddress; const TkId: TTokenId; Number: UInt64; Amount: TBigInteger);
    procedure ClearOnRoadUnconfirmedCache(const Addr: TAddress; const HashList: TArray<PHash>);
    procedure SetCacheLevelForConsensus(Level: Cardinal);
    function NewDb(const DirName: string): TObject; // Placeholder for TDB
    function PrepareOnroadDb: TObject;
    function Plugins: TPlugins;
    procedure SetConsensus(Verifier: IConsensusVerifier; PeriodTimeIndex: ITimeIndex); // Assuming IConsensusVerifier and ITimeIndex are defined
    function DBs(out IndexDB: TIndexDB; out BlockDB: TBlockDB; out StateDB: TStateDB): Boolean;
    function Flusher: TFlusher;
    procedure StopWrite;
    procedure RecoverWrite;
    procedure WriteGenesisCheckSum(const Hash: THash);
    function QueryGenesisCheckSum: PHash;
    procedure CheckRedo;
    procedure CheckRecentBlocks;
    procedure CheckOnRoad;
    function GetStatus: TArray<IDBStatus>; // Assuming IDBStatus is defined
  end;

implementation

end.