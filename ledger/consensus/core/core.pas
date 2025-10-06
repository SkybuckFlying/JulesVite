unit V.Ledger.Consensus.Core;

interface

uses
  System.SysUtils,
  V.Common.Types,
  V.Ledger.Consensus.Core.Stats,
  V.Ledger.Consensus.Core.TimeIndexer;

type
  ISBPStatReader = interface
    ['{B3C7F8D3-8D4C-4D4B-8B4A-7A5D8D3C4B8A}']
    function DayStats(startIndex, endIndex: UInt64): TTuple<TArray<PDayStats>, Error>;
    function GetDayTimeIndex: ITimeIndex;
    function HourStats(startIndex, endIndex: UInt64): TTuple<TArray<PHourStats>, Error>;
    function GetHourTimeIndex: ITimeIndex;
    function PeriodStats(startIndex, endIndex: UInt64): TTuple<TArray<PPeriodStats>, Error>;
    function GetPeriodTimeIndex: ITimeIndex;
    function GetSuccessRateByHour(index: UInt64): TTuple<TDictionary<TAddress, Int32>, Error>;
    function GetNodeCount: Integer;
  end;

implementation

end.