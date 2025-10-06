unit V.Ledger.Consensus.Core.Utils;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Go.Big,
  V.Common.Types,
  V.Interfaces.Core,
  V.Ledger.Consensus.Core.Vote;

type
  IStateCh = interface
    ['{E1D2C3B4-A5F6-4A8B-9C8D-7E6F5A4B3C2D}']
    function GetRegisterList(snapshotHash: THash; gid: TGid): TTuple<TArray<PRegistration>, Error>;
    function GetVoteList(snapshotHash: THash; gid: TGid): TTuple<TArray<PVoteInfo>, Error>;
    function GetConfirmedBalanceList(addrList: TArray<TAddress>; tokenId: TTokenTypeId; sbHash: THash): TTuple<TDictionary<TAddress, IBigInt>, Error>;
    function GetSnapshotHeaderBeforeTime(timestamp: TDateTime): TTuple<ISnapshotBlock, Error>;
    function GetSnapshotBlockByHeight(height: UInt64): TTuple<ISnapshotBlock, Error>;
  end;

function CalVotes(info: TConsensusGroupInfo; hash: THash; rw: IStateCh): TTuple<TArray<PVote>, Error>;
function ConvertVoteToAddress(votes: TArray<PVote>): TArray<TAddress>;

implementation

function VoteCompleting(snapshotHash: THash; vote: PVote; infos: TArray<PVoteInfo>; id: TTokenTypeId; rw: IStateCh): Error;
var
  addrs: TArray<TAddress>;
  v: PVoteInfo;
  balanceMap: TDictionary<TAddress, IBigInt>;
  err: Error;
  balance: IBigInt;
begin
  SetLength(addrs, 0);
  for v in infos do
  begin
    if v.SbpName = vote.Name then
      addrs := addrs + [v.VoteAddr];
  end;
  if Length(addrs) > 0 then
  begin
    Tuple.Create(balanceMap, err) := rw.GetConfirmedBalanceList(addrs, id, snapshotHash);
    if err <> nil then
    begin
      Result := err;
      Exit;
    end;
    for balance in balanceMap.Values do
      vote.Balance.Add(vote.Balance, balance);
  end;
  Result := nil;
end;

function CalVotes(info: TConsensusGroupInfo; hash: THash; rw: IStateCh): TTuple<TArray<PVote>, Error>;
var
  registerList: TArray<PRegistration>;
  err: Error;
  votes: TArray<PVoteInfo>;
  registers: TArray<PVote>;
  v: PRegistration;
  register: PVote;
begin
  Tuple.Create(registerList, err) := rw.GetRegisterList(hash, info.Gid);
  if err <> nil then
  begin
    Result := TTuple.Create(nil, err);
    Exit;
  end;

  Tuple.Create(votes, err) := rw.GetVoteList(hash, info.Gid);
  if err <> nil then
  begin
    Result := TTuple.Create(nil, err);
    Exit;
  end;

  SetLength(registers, 0);
  for v in registerList do
  begin
    New(register);
    register.Balance := TBigInt.New;
    register.Name := v.Name;
    register.Addr := v.BlockProducingAddress;
    err := VoteCompleting(hash, register, votes, info.CountingTokenId, rw);
    if err <> nil then
    begin
      Result := TTuple.Create(nil, err);
      Exit;
    end;
    registers := registers + [register];
  end;
  Result := TTuple.Create(registers, nil);
end;

function ConvertVoteToAddress(votes: TArray<PVote>): TArray<TAddress>;
var
  v: PVote;
begin
  SetLength(Result, Length(votes));
  for v in votes do
    Result := Result + [v.Addr];
end;

end.