unit V.Ledger.Chain.Interface;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Go.Big,
  Go.LevelDB,
  V.Common.Types,
  V.Interfaces,
  V.Ledger.Chain.Block,
  V.Ledger.Chain.Flusher,
  V.Ledger.Chain.Index,
  V.Ledger.Chain.Plugins,
  V.Ledger.Chain.State,
  V.Ledger.Consensus.Core,
  V.VM.Contracts.Dex;

type
  // Forward declaration
  IChain = interface;

  IConsensus = interface
    ['{A1B2C3D4-E5F6-4A8B-9C8D-7E6F5A4B3C2D}']
    function VerifyAccountProducer(Block: PAccountBlock): Boolean;
    function SBPReader: ISBPStatReader;
    function VerifyABsProducer(const Abs: TDictionary<TGid, TArray<IAccountBlock>>): TArray<IAccountBlock>;
  end;

  IChain = interface
    ['{B2C3D4E5-F6A7-4B8C-AD9E-8F706B5C4D3E}']
    // Lifecycle
    procedure Init;
    procedure Start;
    procedure Stop;
    procedure Destroy;
    // Event Manager
    procedure Register(Listener: TObject); // Placeholder for IEventListener
    procedure UnRegister(Listener: TObject);
    // C(Create)
    procedure InsertAccountBlock(VmAccountBlocks: Pointer); // Placeholder for PVmAccountBlock
    function InsertSnapshotBlock(SnapshotBlock: ISnapshotBlock): TArray<IAccountBlock>;
    // D(Delete)
    function DeleteAccountBlocks(const Addr: TAddress; const ToHash: THash): TArray<IAccountBlock>;
    function DeleteAccountBlocksToHeight(const Addr: TAddress; ToHeight: UInt64): TArray<IAccountBlock>;
    function DeleteSnapshotBlocks(const ToHash: THash): TSnapshotChunkArray;
    function DeleteSnapshotBlocksToHeight(ToHeight: UInt64): TSnapshotChunkArray;
    // R(Retrieve)
    function IsGenesisAccountBlock(const Hash: THash): Boolean;
    function IsAccountBlockExisted(const Hash: THash): Boolean;
    function GetAccountBlockByHeight(const Addr: TAddress; Height: UInt64): IAccountBlock;
    function GetAccountBlockHashByHeight(const Addr: TAddress; Height: UInt64): PHash;
    function GetAccountBlockByHash(const BlockHash: THash): IAccountBlock;
    function GetReceiveAbBySendAb(const SendBlockHash: THash): IAccountBlock;
    function IsReceived(const SendBlockHash: THash): Boolean;
    function GetAccountBlocks(const BlockHash: THash; Count: UInt64): TArray<IAccountBlock>;
    function GetCompleteBlockByHash(const BlockHash: THash): IAccountBlock;
    function GetAccountBlocksByHeight(const Addr: TAddress; Height: UInt64; Count: UInt64): TArray<IAccountBlock>;
    function GetAccountBlocksByRange(const Addr: TAddress; Start, &End: UInt64): TArray<IAccountBlock>;
    function GetCallDepth(const SendBlock: THash): Word;
    function IsSeedConfirmedNTimes(const BlockHash: THash; N: UInt64): Boolean;
    function GetConfirmedTimes(const BlockHash: THash): UInt64;
    function GetLatestAccountBlock(const Addr: TAddress): IAccountBlock;
    function GetLatestAccountHeight(const Addr: TAddress): UInt64;
    function IsGenesisSnapshotBlock(const Hash: THash): Boolean;
    function IsSnapshotBlockExisted(const Hash: THash): Boolean;
    function GetGenesisSnapshotBlock: ISnapshotBlock;
    function GetLatestSnapshotBlock: ISnapshotBlock;
    function GetSnapshotHeightByHash(const Hash: THash): UInt64;
    function GetSnapshotHeaderByHeight(Height: UInt64): ISnapshotBlock;
    function GetSnapshotHashByHeight(Height: UInt64): PHash;
    function GetSnapshotBlockByHeight(Height: UInt64): TTuple<ISnapshotBlock, Error>;
    function GetSnapshotHeaderByHash(const Hash: THash): ISnapshotBlock;
    function GetSnapshotBlockByHash(const Hash: THash): TTuple<ISnapshotBlock, Error>;
    function GetRangeSnapshotHeaders(const StartHash, EndHash: THash): TArray<ISnapshotBlock>;
    function GetRangeSnapshotBlocks(const StartHash, EndHash: THash): TArray<ISnapshotBlock>;
    function GetSnapshotHeaders(const BlockHash: THash; Higher: Boolean; Count: UInt64): TArray<ISnapshotBlock>;
    function GetSnapshotBlocks(const BlockHash: THash; Higher: Boolean; Count: UInt64): TArray<ISnapshotBlock>;
    function GetSnapshotHeadersByHeight(Height: UInt64; Higher: Boolean; Count: UInt64): TArray<ISnapshotBlock>;
    function GetSnapshotBlocksByHeight(Height: UInt64; Higher: Boolean; Count: UInt64): TArray<ISnapshotBlock>;
    function GetConfirmSnapshotHeaderByAbHash(const AbHash: THash): ISnapshotBlock;
    function GetConfirmSnapshotBlockByAbHash(const AbHash: THash): ISnapshotBlock;
    function GetSnapshotHeaderBeforeTime(Timestamp: TDateTime): TTuple<ISnapshotBlock, Error>;
    function GetSnapshotHeadersAfterOrEqualTime(EndHashHeight: PHashHeight; StartTime: PDateTime; Producer: PAddress): TTuple<TArray<ISnapshotBlock>, Error>;
    function GetLastUnpublishedSeedSnapshotHeader(const Producer: TAddress; BeforeTime: TDateTime): TTuple<ISnapshotBlock, Error>;
    function GetRandomSeed(const SnapshotHash: THash; N: Integer): UInt64;
    function GetSnapshotBlockByContractMeta(const Addr: TAddress; const FromHash: THash): ISnapshotBlock;
    function GetSeedConfirmedSnapshotBlock(const Addr: TAddress; const FromHash: THash): ISnapshotBlock;
    function GetSeed(LimitSb: ISnapshotBlock; const FromHash: THash): UInt64;
    function GetSubLedger(StartHeight, EndHeight: UInt64): TSnapshotChunkArray;
    function GetSubLedgerAfterHeight(Height: UInt64): TSnapshotChunkArray;
    function GetAllUnconfirmedBlocks: TArray<IAccountBlock>;
    function GetUnconfirmedBlocks(const Addr: TAddress): TArray<IAccountBlock>;
    function GetContentNeedSnapshot: Pointer; // TSnapshotContent
    function GetContentNeedSnapshotRange: TDictionary<TAddress, Pointer>; // PHeightRange
    procedure IterateContracts(IterateFunc: TFunc<TAddress, PContractMeta, Boolean>);
    procedure IterateAccounts(IterateFunc: TFunc<TAddress, UInt64, Boolean>);
    function GetBalance(const Addr: TAddress; const TokenId: TTokenTypeId): IBigInt;
    function GetBalanceMap(const Addr: TAddress): TDictionary<TTokenTypeId, IBigInt>;
    function GetConfirmedBalanceList(const AddrList: TArray<TAddress>; const TokenId: TTokenTypeId; const SbHash: THash): TTuple<TDictionary<TAddress, IBigInt>, Error>;
    function GetContractCode(const ContractAddr: TAddress): TBytes;
    function GetContractMeta(const ContractAddress: TAddress): TTuple<PContractMeta, Error>;
    function GetContractMetaInSnapshot(const ContractAddress: TAddress; SnapshotHeight: UInt64): PContractMeta;
    function GetContractList(const Gid: TGid): TArray<TAddress>;
    function GetQuotaUnused(const Address: TAddress): UInt64;
    function GetGlobalQuota: Pointer; // TQuotaInfo
    function GetQuotaUsedList(const Address: TAddress): TArray<Pointer>; // TQuotaInfo
    function GetStorageIterator(const Address: TAddress; const Prefix: TBytes): Pointer; // IStorageIterator
    function GetValue(const Address: TAddress; const Key: TBytes): TBytes;
    function GetVmLogList(LogListHash: PHash): Pointer; // TVmLogList
    function GetVMLogListByAddress(const Address: TAddress; Start, &End: UInt64; Id: PHash): Pointer;
    function GetRegisterList(const SnapshotHash: THash; const Gid: TGid): TTuple<TArray<PRegistration>, Error>;
    function GetAllRegisterList(const SnapshotHash: THash; const Gid: TGid): TTuple<TArray<PRegistration>, Error>;
    function GetConsensusGroupList(const SnapshotHash: THash): TTuple<TArray<PConsensusGroupInfo>, Error>;
    function GetConsensusGroup(const SnapshotHash: THash; const Gid: TGid): PConsensusGroupInfo;
    function GetVoteList(const SnapshotHash: THash; const Gid: TGid): TTuple<TArray<PVoteInfo>, Error>;
    function GetStakeBeneficialAmount(const Addr: TAddress): IBigInt;
    function GetStakeQuota(const Addr: TAddress; out Quota: Pointer): IBigInt; // TQuota
    function GetStakeQuotas(const AddrList: TArray<TAddress>): TDictionary<TAddress, Pointer>;
    function GetTokenInfoById(const TokenId: TTokenTypeId): Pointer; // PTokenInfo
    function GetAllTokenInfo: TDictionary<TTokenTypeId, Pointer>;
    function CalVoteDetails(const Gid: TGid; Info: PGroupInfo; SnapshotBlock: THashHeight): TArray<Pointer>; // IVoteDetails
    function GetStakeListByPage(const SnapshotHash: THash; const LastKey: TBytes; Count: UInt64; out NextKey: TBytes): TArray<Pointer>; // PStakeInfo
    function GetDexFundsByPage(const SnapshotHash: THash; const LastAddress: TAddress; Count: Integer): TArray<Pointer>; // PFund
    function GetDexStakeListByPage(const SnapshotHash: THash; const LastKey: TBytes; Count: Integer; out NextKey: TBytes): TArray<Pointer>; // PDelegateStakeInfo
    function GetLedgerReaderByHeight(StartHeight, EndHeight: UInt64): ILedgerReader;
    function GetSyncCache: ISyncCache;
    function LoadOnRoadRange(const Gid: TGid; Fn: TFunc<Pointer, Boolean>): Boolean; // TLoadOnroadFn
    procedure DeleteOnRoad(const ToAddress: TAddress; const SendBlockHash: THash);
    function GetOnRoadBlocksByAddr(const Addr: TAddress; PageNum, PageSize: Integer): TArray<IAccountBlock>;
    function LoadAllOnRoad(out Map: TDictionary<TAddress, TArray<THash>>): Boolean;
    function GetAccountOnRoadInfo(const Addr: TAddress): Pointer; // PAccountInfo
    function GetOnRoadInfoUnconfirmedHashList(const Addr: TAddress): TArray<PHash>;
    procedure UpdateOnRoadInfo(const Addr: TAddress; const TkId: TTokenTypeId; Number: UInt64; Amount: IBigInt);
    procedure ClearOnRoadUnconfirmedCache(const Addr: TAddress; const HashList: TArray<PHash>);
    procedure SetCacheLevelForConsensus(Level: Cardinal);
    function NewDb(const DirName: string): TTuple<ILevelDB, Error>;
    function PrepareOnroadDb: ILevelDB;
    function Plugins: TPlugins;
    procedure SetConsensus(Verifier: IConsensusVerifier; PeriodTimeIndex: ITimeIndex);
    function DBs(out IndexDB: TIndexDB; out BlockDB: Pointer; out StateDB: TStateDB): Boolean; // TBlockDB
    function Flusher: TFlusher;
    procedure StopWrite;
    procedure RecoverWrite;
    procedure WriteGenesisCheckSum(const Hash: THash);
    function QueryGenesisCheckSum: PHash;
    procedure CheckRedo;
    procedure CheckRecentBlocks;
    procedure CheckOnRoad;
    function GetStatus: TArray<Pointer>; // IDBStatus
  end;

implementation

end.