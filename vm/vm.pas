{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/vm/vm.go
}
unit V.VM;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  V.Common.Types, V.Interfaces, V.Interfaces.Core, V.VM.Util, V.VM.Quota,
  V.VM.Interpreter, V.VM.Contract;

type
  TCanTransferFunc = function(DB: IVmDb; const TokenTypeId: TTokenId; TokenAmount, FeeAmount: TBigInteger): Boolean;

  TVM = class
  private
    FAbort: Integer;
    FSendBlockList: TList<PAccountBlock>;
    FInterpreter: TInterpreter;
    FGlobalStatus: IGlobalStatus;
    FReader: IConsensusReader;
    FLatestSnapshotHeight: UInt64;
    FGasTable: TQuotaTable;
    function GetGlobalStatus: IGlobalStatus;
    function GetConsensusReader: IConsensusReader;
    procedure UpdateBlock(DB: IVmDb; Block: PAccountBlock; Err: Exception; QStakeUsed, QUsed: UInt64);
    function DoSendBlockList(DB: IVmDb): IVmDb;
    procedure Revert(DB: IVmDb);
    procedure AppendBlock(Block: PAccountBlock);
  public
    constructor Create(ACr: IConsensusReader);
    destructor Destroy; override;
    procedure Cancel;
    function RunV2(DB: IVmDb; Block, SendBlock: PAccountBlock; Status: IGlobalStatus): TObject; // Returns VmAccountBlock, isRetry, err
    function OffChainReader(DB: IVmDb; const Code, Data: TBytes): TBytes;
  end;

implementation

uses System.Threading, V.Common.Upgrade, V.VM.Config, V.VM.Contracts;

{ TVM }

constructor TVM.Create(ACr: IConsensusReader);
begin
  inherited Create;
  FReader := ACr;
  FSendBlockList := TList<PAccountBlock>.Create;
end;

destructor TVM.Destroy;
begin
  FSendBlockList.Free;
  inherited Destroy;
end;

procedure TVM.Cancel;
begin
  TInterlocked.Exchange(FAbort, 1);
end;

function TVM.RunV2(DB: IVmDb; Block, SendBlock: PAccountBlock; Status: IGlobalStatus): TObject;
var
  sb: PSnapshotBlock;
  blockCopy: PAccountBlock;
  quotaTotal, quotaAddition: UInt64;
begin
  // Simplified logic. A full implementation would be much more complex.
  sb := DB.LatestSnapshotBlock;
  FLatestSnapshotHeight := sb.Height;
  // FGasTable := GetQuotaTableByHeight(sb.Height); // Placeholder
  blockCopy := new PAccountBlock;
  blockCopy^ := Block^;

  if blockCopy.IsSendBlock then
  begin
    // ... logic for send blocks ...
  end
  else
  begin
    FInterpreter := TInterpreter.Create(sb.Height, False);
    FGlobalStatus := Status;
    // ... logic for receive blocks ...
  end;
  Result := nil;
end;

function TVM.OffChainReader(DB: IVmDb; const Code, Data: TBytes): TBytes;
var
  sb: PSnapshotBlock;
  c: TContract;
begin
  sb := DB.LatestSnapshotBlock;
  FInterpreter := TInterpreter.Create(sb.Height, True);
  // FGasTable := GetQuotaTableByHeight(sb.Height);
  c := TContract.Create(TAccountBlock.Create(AccountAddress: DB.Address), DB, TAccountBlock.Create(ToAddress: DB.Address), Data, OffChainReaderGas);
  c.SetCallCode(DB.Address^, Code);
  Result := c.Run(Self);
end;

function TVM.GetGlobalStatus: IGlobalStatus;
begin
  Result := FGlobalStatus;
end;

function TVM.GetConsensusReader: IConsensusReader;
begin
  Result := FReader;
end;

procedure TVM.UpdateBlock(DB: IVmDb; Block: PAccountBlock; Err: Exception; QStakeUsed, QUsed: UInt64);
begin
  // Placeholder
end;

function TVM.DoSendBlockList(DB: IVmDb): IVmDb;
begin
  Result := DB; // Placeholder
end;

procedure TVM.Revert(DB: IVmDb);
begin
  FSendBlockList.Clear;
  DB.Reset;
end;

procedure TVM.AppendBlock(Block: PAccountBlock);
begin
  FSendBlockList.Add(Block);
end;

end.