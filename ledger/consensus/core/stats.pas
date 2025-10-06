unit V.Ledger.Consensus.Core.Stats;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Go.Big,
  V.Common.Types;

type
  PBigIntWrapper = ^TBigIntWrapper;
  TBigIntWrapper = record
    Int: IBigInt;
  end;

  PSbpStats = ^TSbpStats;
  TSbpStats = record
    Index: UInt64;
    BlockNum: UInt64;
    ExceptedBlockNum: UInt64;
    VoteCnt: PBigIntWrapper;
    Name: string;
  end;

  PBaseStats = ^TBaseStats;
  TBaseStats = record
    Index: UInt64;
    Stats: TDictionary<TAddress, PSbpStats>;
  end;

  PHourStats = ^THourStats;
  THourStats = record
    BaseStats: TBaseStats;
  end;

  PPeriodStats = ^TPeriodStats;
  TPeriodStats = record
    BaseStats: TBaseStats;
  end;

  PDayStats = ^TDayStats;
  TDayStats = record
    Index: UInt64;
    Stats: TDictionary<string, PSbpStats>;
    BlockTotal: UInt64;
    VoteSum: PBigIntWrapper;
  end;

implementation

end.