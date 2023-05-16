# Summary
- [Home](README.md)
# src
  - [❱ external](src/external/README.md)
    - [❱ interfaces](src/external/interfaces/README.md)
      - [❱ chainlink](src/external/interfaces/chainlink/README.md)
        - [AggregatorInterface](src/external/interfaces/chainlink/AggregatorInterface.sol/contract.AggregatorInterface.md)
        - [AggregatorV2V3Interface](src/external/interfaces/chainlink/AggregatorV2V3Interface.sol/contract.AggregatorV2V3Interface.md)
        - [AggregatorV3Interface](src/external/interfaces/chainlink/AggregatorV3Interface.sol/contract.AggregatorV3Interface.md)
  - [❱ fee-manager](src/fee-manager/README.md)
    - [FeeManager](src/fee-manager/FeeManager.sol/contract.FeeManager.md)
  - [❱ interfaces](src/interfaces/README.md)
    - [IController](src/interfaces/IController.sol/contract.IController.md)
    - [IFeeManager](src/interfaces/IFeeManager.sol/contract.IFeeManager.md)
    - [UserPoolDetails](src/interfaces/ILiquidityPool.sol/struct.UserPoolDetails.md)
    - [ILiquidityPool](src/interfaces/ILiquidityPool.sol/contract.ILiquidityPool.md)
    - [LiquidityPoolConfig](src/interfaces/ILiquidityPoolAdapter.sol/struct.LiquidityPoolConfig.md)
    - [ILiquidityPoolAdapter](src/interfaces/ILiquidityPoolAdapter.sol/contract.ILiquidityPoolAdapter.md)
    - [ILiquidityPoolVault](src/interfaces/ILiquidityPoolVault.sol/contract.ILiquidityPoolVault.md)
    - [IPriceFeed](src/interfaces/IPriceFeed.sol/contract.IPriceFeed.md)
    - [IPriceFeedAdapter](src/interfaces/IPriceFeedAdapter.sol/contract.IPriceFeedAdapter.md)
    - [IPriceFeedAggregator](src/interfaces/IPriceFeedAggregator.sol/contract.IPriceFeedAggregator.md)
    - [OpenPositionParams](src/interfaces/ITradeManager.sol/struct.OpenPositionParams.md)
    - [ClosePositionParams](src/interfaces/ITradeManager.sol/struct.ClosePositionParams.md)
    - [PartiallyClosePositionParams](src/interfaces/ITradeManager.sol/struct.PartiallyClosePositionParams.md)
    - [RemoveMarginFromPositionParams](src/interfaces/ITradeManager.sol/struct.RemoveMarginFromPositionParams.md)
    - [AddMarginToPositionParams](src/interfaces/ITradeManager.sol/struct.AddMarginToPositionParams.md)
    - [ExtendPositionParams](src/interfaces/ITradeManager.sol/struct.ExtendPositionParams.md)
    - [ExtendPositionToLeverageParams](src/interfaces/ITradeManager.sol/struct.ExtendPositionToLeverageParams.md)
    - [Constraints](src/interfaces/ITradeManager.sol/struct.Constraints.md)
    - [OpenPositionOrder](src/interfaces/ITradeManager.sol/struct.OpenPositionOrder.md)
    - [ClosePositionOrder](src/interfaces/ITradeManager.sol/struct.ClosePositionOrder.md)
    - [PartiallyClosePositionOrder](src/interfaces/ITradeManager.sol/struct.PartiallyClosePositionOrder.md)
    - [ExtendPositionOrder](src/interfaces/ITradeManager.sol/struct.ExtendPositionOrder.md)
    - [ExtendPositionToLeverageOrder](src/interfaces/ITradeManager.sol/struct.ExtendPositionToLeverageOrder.md)
    - [AddMarginToPositionOrder](src/interfaces/ITradeManager.sol/struct.AddMarginToPositionOrder.md)
    - [RemoveMarginFromPositionOrder](src/interfaces/ITradeManager.sol/struct.RemoveMarginFromPositionOrder.md)
    - [UpdateData](src/interfaces/ITradeManager.sol/struct.UpdateData.md)
    - [TradeId](src/interfaces/ITradeManager.sol/struct.TradeId.md)
    - [ITradeManager](src/interfaces/ITradeManager.sol/contract.ITradeManager.md)
    - [ITradeManagerOrders](src/interfaces/ITradeManagerOrders.sol/contract.ITradeManagerOrders.md)
    - [PositionDetails](src/interfaces/ITradePair.sol/struct.PositionDetails.md)
    - [PricePair](src/interfaces/ITradePair.sol/struct.PricePair.md)
    - [ITradePair](src/interfaces/ITradePair.sol/contract.ITradePair.md)
    - [ITradePairHelper](src/interfaces/ITradePairHelper.sol/contract.ITradePairHelper.md)
    - [ITradeSignature](src/interfaces/ITradeSignature.sol/contract.ITradeSignature.md)
    - [IUnlimitedOwner](src/interfaces/IUnlimitedOwner.sol/contract.IUnlimitedOwner.md)
    - [IUpdatable](src/interfaces/IUpdatable.sol/contract.IUpdatable.md)
    - [Tier](src/interfaces/IUserManager.sol/enum.Tier.md)
    - [IUserManager](src/interfaces/IUserManager.sol/contract.IUserManager.md)
  - [❱ lib](src/lib/README.md)
    - [FeeBuffer](src/lib/FeeBuffer.sol/struct.FeeBuffer.md)
    - [FeeBufferLib](src/lib/FeeBuffer.sol/contract.FeeBufferLib.md)
    - [FeeIntegral](src/lib/FeeIntegral.sol/struct.FeeIntegral.md)
    - [FeeIntegralLib](src/lib/FeeIntegral.sol/contract.FeeIntegralLib.md)
    - [FundingFee](src/lib/FundingFee.sol/contract.FundingFee.md)
    - [Position](src/lib/PositionMaths.sol/struct.Position.md)
    - [PositionMaths](src/lib/PositionMaths.sol/contract.PositionMaths.md)
    - [PositionStats](src/lib/PositionStats.sol/struct.PositionStats.md)
    - [PositionStatsLib](src/lib/PositionStats.sol/contract.PositionStatsLib.md)
  - [❱ liquidity-pools](src/liquidity-pools/README.md)
    - [UserPoolDeposit](src/liquidity-pools/LiquidityPool.sol/struct.UserPoolDeposit.md)
    - [UserPoolInfo](src/liquidity-pools/LiquidityPool.sol/struct.UserPoolInfo.md)
    - [LockPoolInfo](src/liquidity-pools/LiquidityPool.sol/struct.LockPoolInfo.md)
    - [LiquidityPool](src/liquidity-pools/LiquidityPool.sol/contract.LiquidityPool.md)
    - [LiquidityPoolAdapter](src/liquidity-pools/LiquidityPoolAdapter.sol/contract.LiquidityPoolAdapter.md)
    - [LiquidityPoolVault](src/liquidity-pools/LiquidityPoolVault.sol/contract.LiquidityPoolVault.md)
  - [❱ price-feed](src/price-feed/README.md)
    - [ChainlinkUsdPriceFeed](src/price-feed/ChainlinkUsdPriceFeed.sol/contract.ChainlinkUsdPriceFeed.md)
    - [ChainlinkUsdPriceFeedPrevious](src/price-feed/ChainlinkUsdPriceFeedPrevious.sol/contract.ChainlinkUsdPriceFeedPrevious.md)
    - [PriceFeedAdapter](src/price-feed/PriceFeedAdapter.sol/contract.PriceFeedAdapter.md)
    - [PriceFeedAggregator](src/price-feed/PriceFeedAggregator.sol/contract.PriceFeedAggregator.md)
    - [PriceData](src/price-feed/UnlimitedPriceFeed.sol/struct.PriceData.md)
    - [UnlimitedPriceFeed](src/price-feed/UnlimitedPriceFeed.sol/contract.UnlimitedPriceFeed.md)
    - [UnlimitedPriceFeedAdapter](src/price-feed/UnlimitedPriceFeedAdapter.sol/contract.UnlimitedPriceFeedAdapter.md)
    - [PriceData](src/price-feed/UnlimitedPriceFeedUpdater.sol/struct.PriceData.md)
    - [UnlimitedPriceFeedUpdater](src/price-feed/UnlimitedPriceFeedUpdater.sol/contract.UnlimitedPriceFeedUpdater.md)
  - [❱ shared](src/shared/README.md)
    - [Constants](src/shared/Constants.sol/constants.Constants.md)
    - [UnlimitedOwnable](src/shared/UnlimitedOwnable.sol/contract.UnlimitedOwnable.md)
  - [❱ sys-controller](src/sys-controller/README.md)
    - [Controller](src/sys-controller/Controller.sol/contract.Controller.md)
    - [UnlimitedOwner](src/sys-controller/UnlimitedOwner.sol/contract.UnlimitedOwner.md)
  - [❱ trade-manager](src/trade-manager/README.md)
    - [UsePrice](src/trade-manager/TradeManager.sol/enum.UsePrice.md)
    - [TradeManager](src/trade-manager/TradeManager.sol/contract.TradeManager.md)
    - [TradeManagerOrders](src/trade-manager/TradeManagerOrders.sol/contract.TradeManagerOrders.md)
    - [TradeSignature](src/trade-manager/TradeSignature.sol/contract.TradeSignature.md)
  - [❱ trade-pair](src/trade-pair/README.md)
    - [TradePair](src/trade-pair/TradePair.sol/contract.TradePair.md)
    - [TradePairHelper](src/trade-pair/TradePairHelper.sol/contract.TradePairHelper.md)
  - [❱ user-manager](src/user-manager/README.md)
    - [DailyVolumes](src/user-manager/UserManager.sol/struct.DailyVolumes.md)
    - [FeeVolumes](src/user-manager/UserManager.sol/struct.FeeVolumes.md)
    - [FeeSizes](src/user-manager/UserManager.sol/struct.FeeSizes.md)
    - [ManualUserTier](src/user-manager/UserManager.sol/struct.ManualUserTier.md)
    - [UserManager](src/user-manager/UserManager.sol/contract.UserManager.md)