{
  This unit is a temporary placeholder for the Go 'interfaces' package.
  It provides minimal interface definitions to allow the conversion of dependent units.
}
unit V.Interfaces;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  V.Common.Types,
  V.Interfaces.Core;

type
  IConsensusVerifier = interface
    ['{E4D3C2B1-A9F8-4E7D-8C6B-5A4B3C2D1E0F}']
    function VerifySnapshotProducer(header: ISnapshotBlock): TTuple<Boolean, Error>;
    function VerifyABsProducer(abs: TDictionary<TGid, TArray<IAccountBlock>>): TTuple<TArray<IAccountBlock>, Error>;
    function VerifyAccountProducer(accountBlock: IAccountBlock): TTuple<Boolean, Error>;
  end;

  // ISyncCache represents a cache for synchronization.
  ISyncCache = interface
    ['{C1C2D3E4-F5F6-4A8B-9C8D-7E6F5A4B3C2D}']
    // Placeholder methods
  end;

  // ILedgerReader provides read-only access to the ledger.
  ILedgerReader = interface
    ['{B1A2C3D4-E5F6-4A8B-9C8D-7E6F5A4B3C2D}']
    // Placeholder methods
  end;

  // TSegment is a continuous chunk list
  TSegment = record
    From, To_: UInt64;
    Hash, PrevHash: THash;
    Points: TArray<PHashHeight>;
  end;
  PSegment = ^TSegment;
  TSegmentList = TArray<TSegment>;

implementation

end.