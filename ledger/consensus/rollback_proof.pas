unit V.Ledger.Consensus.RollbackProof;

interface

uses
  System.SysUtils,
  V.Common.Types,
  V.Interfaces.Core,
  V.Ledger.Chain.Interface;

type
  IRollbackProof = interface
    ['{F8E7D6C5-B4A3-9281-7E6F-5A4B3C2D1E0F}']
    function Proof(hash: THash; t: TDateTime): TTuple<ISnapshotBlock, Error>;
    function ProofEmpty(stime, etime: TDateTime): TTuple<Boolean, Error>;
    function ProofHash(t: TDateTime): TTuple<THash, Error>;
  end;

  TRollbackProof = class(TInterfacedObject, IRollbackProof)
  private
    FRw: IChain;
  public
    constructor Create(rw: IChain);
    function Proof(hash: THash; t: TDateTime): TTuple<ISnapshotBlock, Error>;
    function ProofEmpty(stime, etime: TDateTime): TTuple<Boolean, Error>;
    function ProofHash(t: TDateTime): TTuple<THash, Error>;
  end;

function NewRollbackProof(rw: IChain): IRollbackProof;

var
  ErrNotFoundBlock: Error;

implementation

uses System.DateUtils;

{ TRollbackProof }

constructor TRollbackProof.Create(rw: IChain);
begin
  FRw := rw;
end;

function TRollbackProof.Proof(hash: THash; t: TDateTime): TTuple<ISnapshotBlock, Error>;
var
  block: ISnapshotBlock;
  err: Error;
begin
  Tuple.Create(block, err) := FRw.GetSnapshotHeaderBeforeTime(t);
  if err <> nil then
  begin
    Result := TTuple.Create(nil, err);
    Exit;
  end;
  if block = nil then
  begin
    Result := TTuple.Create(nil, EProgrammerException.CreateFmt('before time[%s] block not exist', [DateTimeToStr(t)]));
    Exit;
  end;

  if block.Hash <> hash then
  begin
    Result := TTuple.Create(nil, EProgrammerException.CreateFmt('block[%s][%s] proof fail.', [hash.ToString, block.Hash.ToString]));
    Exit;
  end;
  Result := TTuple.Create(block, nil);
end;

function TRollbackProof.ProofEmpty(stime, etime: TDateTime): TTuple<Boolean, Error>;
var
  block: ISnapshotBlock;
  err: Error;
begin
  Tuple.Create(block, err) := FRw.GetSnapshotHeaderBeforeTime(etime);
  if err <> nil then
  begin
    Result := TTuple.Create(False, err);
    Exit;
  end;
  if block = nil then
  begin
    Result := TTuple.Create(False, EProgrammerException.CreateFmt('before time[%s] block not exist', [DateTimeToStr(etime)]));
    Exit;
  end;
  if not (etime > block.Timestamp) then
  begin
    Result := TTuple.Create(False, EProgrammerException.CreateFmt('GetSnapshotHeaderBeforeTime fail. [%s]-[%s]', [DateTimeToStr(etime), DateTimeToStr(block.Timestamp)]));
    Exit;
  end;
  if block.Timestamp < stime then
    Result := TTuple.Create(True, nil)
  else
    Result := TTuple.Create(False, nil);
end;

function TRollbackProof.ProofHash(t: TDateTime): TTuple<THash, Error>;
var
  block: ISnapshotBlock;
  err: Error;
begin
  Tuple.Create(block, err) := FRw.GetSnapshotHeaderBeforeTime(t);
  if err <> nil then
  begin
    Result := TTuple.Create(Default(THash), err);
    Exit;
  end;
  if block = nil then
  begin
    Result := TTuple.Create(Default(THash), EProgrammerException.CreateFmt('before time[%s] block not exist', [DateTimeToStr(t)]));
    Exit;
  end;
  Result := TTuple.Create(block.Hash, nil);
end;

function NewRollbackProof(rw: IChain): IRollbackProof;
begin
  Result := TRollbackProof.Create(rw);
end;

initialization
  ErrNotFoundBlock := EProgrammerException.Create('block not found');
end.