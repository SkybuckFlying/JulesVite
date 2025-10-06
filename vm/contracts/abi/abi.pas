{
  This unit is a temporary placeholder for the Go 'vm/contracts/abi' package.
  It provides minimal definitions to allow the conversion of dependent units.
}
unit V.VM.Contracts.ABI;

interface

uses
  System.SysUtils;

type
  TMethod = record
    Name: string;
  end;

  TAbiContract = class
  public
    function MethodById(const Selector: TBytes): TMethod;
  end;

const
  // Quota
  MethodNameStake = 'Stake';
  MethodNameCancelStake = 'CancelStake';
  MethodNameDelegateStake = 'DelegateStake';
  MethodNameCancelDelegateStake = 'CancelDelegateStake';
  MethodNameStakeV2 = 'StakeV2';
  MethodNameCancelStakeV2 = 'CancelStakeV2';
  MethodNameDelegateStakeV2 = 'DelegateStakeV2';
  MethodNameCancelDelegateStakeV2 = 'CancelDelegateStakeV2';
  MethodNameStakeV3 = 'StakeV3';
  MethodNameCancelStakeV3 = 'CancelStakeV3';
  MethodNameStakeWithCallback = 'StakeWithCallback';
  MethodNameCancelStakeWithCallback = 'CancelStakeWithCallback';

  // Governance
  MethodNameRegister = 'Register';
  MethodNameRevoke = 'Revoke';
  MethodNameWithdrawReward = 'WithdrawReward';
  MethodNameUpdateBlockProducingAddress = 'UpdateBlockProducingAddress';
  MethodNameVote = 'Vote';
  MethodNameCancelVote = 'CancelVote';
  MethodNameUpdateBlockProducintAddressV2 = 'UpdateBlockProducingAddressV2';
  MethodNameRevokeV2 = 'RevokeV2';
  MethodNameWithdrawRewardV2 = 'WithdrawRewardV2';
  MethodNameRegisterV3 = 'RegisterV3';
  MethodNameUpdateBlockProducintAddressV3 = 'UpdateBlockProducingAddressV3';
  MethodNameUpdateSBPRewardWithdrawAddress = 'UpdateSBPRewardWithdrawAddress';
  MethodNameRevokeV3 = 'RevokeV3';
  MethodNameWithdrawRewardV3 = 'WithdrawRewardV3';
  MethodNameVoteV3 = 'VoteV3';
  MethodNameCancelVoteV3 = 'CancelVoteV3';

  // Asset
  MethodNameIssue = 'Issue';
  MethodNameReIssue = 'ReIssue';
  MethodNameBurn = 'Burn';
  MethodNameBurnV2 = 'BurnV2';
  MethodNameTransferOwnership = 'TransferOwnership';
  MethodNameDisableReIssue = 'DisableReIssue';
  MethodNameGetTokenInfo = 'GetTokenInfo';
  MethodNameIssueV2 = 'IssueV2';
  MethodNameReIssueV2 = 'ReIssueV2';
  MethodNameDisableReIssueV2 = 'DisableReIssueV2';
  MethodNameTransferOwnershipV2 = 'TransferOwnershipV2';
  MethodNameGetTokenInfoV3 = 'GetTokenInfoV3';

  // DexFund
  MethodNameDexFundUserDeposit = 'DexFundUserDeposit';
  MethodNameDexFundUserWithdraw = 'DexFundUserWithdraw';
  MethodNameDexFundNewMarket = 'DexFundNewMarket';
  MethodNameDexFundNewOrder = 'DexFundNewOrder';
  MethodNameDexFundSettleOrders = 'DexFundSettleOrders';
  MethodNameDexFundPeriodJob = 'DexFundPeriodJob';
  MethodNameDexFundPledgeForVx = 'DexFundPledgeForVx';
  MethodNameDexFundPledgeForVip = 'DexFundPledgeForVip';
  MethodNameDexFundPledgeCallback = 'DexFundPledgeCallback';
  MethodNameDexFundCancelPledgeCallback = 'DexFundCancelPledgeCallback';
  MethodNameDexFundGetTokenInfoCallback = 'DexFundGetTokenInfoCallback';
  MethodNameDexFundOwnerConfig = 'DexFundOwnerConfig';
  MethodNameDexFundOwnerConfigTrade = 'DexFundOwnerConfigTrade';
  MethodNameDexFundMarketOwnerConfig = 'DexFundMarketOwnerConfig';
  MethodNameDexFundTransferTokenOwner = 'DexFundTransferTokenOwner';
  MethodNameDexFundNotifyTime = 'DexFundNotifyTime';
  MethodNameDexFundNewInviter = 'DexFundNewInviter';
  MethodNameDexFundBindInviteCode = 'DexFundBindInviteCode';
  MethodNameDexFundEndorseVxMinePool = 'DexFundEndorseVxMinePool';
  MethodNameDexFundSettleMakerMinedVx = 'DexFundSettleMakerMinedVx';
  MethodNameDexFundSettleOrdersV2 = 'DexFundSettleOrdersV2';
  MethodNameDexFundBindInviteCodeV2 = 'DexFundBindInviteCodeV2';
  MethodNameDexFundEndorseVxV2 = 'DexFundEndorseVxV2';
  MethodNameDexFundSettleMakerMinedVxV2 = 'DexFundSettleMakerMinedVxV2';
  MethodNameDexFundStakeForSuperVip = 'DexFundStakeForSuperVip';
  MethodNameDexFundConfigMarketsAgent = 'DexFundConfigMarketsAgent';
  MethodNameDexFundNewAgentOrder = 'DexFundPlaceAgentOrder';
  MethodNameDexFundLockVxForDividend = 'DexFundLockVxForDividend';
  MethodNameDexFundSwitchConfig = 'DexFundSwitchConfig';
  MethodNameDexFundStakeForPrincipalSVIP = 'DexFundStakeForPrincipalSVIP';
  MethodNameDexFundCancelStakeById = 'DexFundCancelStakeById';
  MethodNameDexFundDelegateStakeCallbackV2 = 'DexFundDelegateStakeCallbackV2';
  MethodNameDexFundCancelDelegateStakeCallbackV2 = 'DexFundCancelDelegateStakeCallbackV2';
  MethodNameDexFundCancelOrderBySendHash = 'DexFundCancelOrderBySendHash';
  MethodNameDexFundCommonAdminConfig = 'DexFundCommonAdminConfig';
  MethodNameDexFundTransfer = 'DexFundTransfer';
  MethodNameDexFundAgentDeposit = 'DexFundAgentDeposit';
  MethodNameDexFundAssignedWithdraw = 'DexFundAssignedWithdraw';

  // DexTrade
  MethodNameDexTradeNewOrder = 'DexTradeNewOrder';
  MethodNameDexTradeCancelOrder = 'DexTradeCancelOrder';
  MethodNameDexTradeNotifyNewMarket = 'DexTradeNotifyNewMarket';
  MethodNameDexTradeClearExpiredOrders = 'DexTradeClearExpiredOrders';
  MethodNameDexTradePlaceOrder = 'DexTradePlaceOrder';
  MethodNameDexTradeCancelOrderV2 = 'DexTradeCancelOrderV2';
  MethodNameDexTradeCancelOrderByTransactionHash = 'DexTradeCancelOrderByTransactionHash';
  MethodNameDexTradeInnerCancelOrderBySendHash = 'DexTradeInnerCancelOrderBySendHash';

implementation

{ TAbiContract }

function TAbiContract.MethodById(const Selector: TBytes): TMethod;
begin
  // Placeholder
end;

end.