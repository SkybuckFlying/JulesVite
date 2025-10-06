{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/vm/params.go
}
unit V.VM.Params;

interface

uses
  System.SysUtils, System.Numerics;

const
  CallDepth = 512;
  StackLimit = 1024;
  MaxCodeSize = 24575;
  OffChainReaderGas = 1000000;
  SnapshotCountMin = 0;
  SnapshotCountMax = 75;
  SnapshotWithSeedCountMin = 0;
  SnapshotWithSeedCountMax = 75;
  ContractModifyStorageMax = 100;
  Retry = True;
  NoRetry = False;

var
  CreateContractFee: TBigInteger;

implementation

uses V.Common.Helper, V.VM.Util;

initialization
  CreateContractFee := Big10 * AttovPerVite;
end.