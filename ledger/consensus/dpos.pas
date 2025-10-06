unit V.Ledger.Consensus.Dpos;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  V.Common.Types,
  V.Ledger.Consensus.Result,
  V.Ledger.Consensus.Core.Group;

type
  IDposReader = interface
    ['{A7E1C4B5-8D4C-4D4B-8B4A-7A5D8D3C4B8B}']
    function ElectionIndex(index: UInt64): TTuple<TElectionResult, Error>;
    function GetInfo: TGroupInfo;
    function Time2Index(t: TDateTime): UInt64;
    function Index2Time(i: UInt64): TTuple<TDateTime, TDateTime>;
    function GenProofTime(t: UInt64): TDateTime;
    function VerifyProducer(address: TAddress; t: TDateTime): TTuple<Boolean, Error>;
  end;

  IDposVerifier = interface
    ['{B8E1C4B5-8D4C-4D4B-8B4A-7A5D8D3C4B8C}']
    // Placeholder
  end;

implementation

end.