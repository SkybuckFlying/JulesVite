{
  This unit is a temporary placeholder for the Go 'interfaces/core' package.
  It provides minimal type definitions to allow the conversion of dependent units.
}
unit V.Interfaces.Core;

interface

uses
  System.SysUtils, V.Common.Types;

type
  // TAccountBlock is a placeholder for the account block structure.
  TAccountBlock = record
    Hash: THash;
    PrevHash: THash;
    AccountAddress: TAddress;
    Height: UInt64;
  end;
  PAccountBlock = ^TAccountBlock;
  TAccountBlockArray = array of PAccountBlock;

  // TSnapshotBlock is a placeholder for the snapshot block structure.
  TSnapshotBlock = record
    Hash: THash;
    PrevHash: THash;
    Height: UInt64;
  end;
  PSnapshotBlock = ^TSnapshotBlock;

  // THashHeight combines a hash and a height.
  THashHeight = record
    Hash: THash;
    Height: UInt64;
  end;
  PHashHeight = ^THashHeight;

  // TSnapshotChunk represents a chunk of the snapshot chain.
  TSnapshotChunk = record
    SnapshotBlock: PSnapshotBlock;
    AccountBlocks: TAccountBlockArray;
  end;
  TSnapshotChunkArray = array of TSnapshotChunk;

implementation

end.