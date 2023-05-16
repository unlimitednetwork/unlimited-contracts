// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "src/trade-pair/TradePair.sol";
import "test/setup/WithMocks.t.sol";

contract WithTradePair is WithMocks {
    ITradePair tradePair;

    /// @notice this function is necessary to exclude this contract from test coverage
    function testMock() public override(WithMocks) {}

    function deployTradePair() public {
        // Deploy
        vm.warp(0);
        TradePair tradePairImplementation = new TradePair(
            mockUnlimitedOwner,
            mockTradeManager,
            mockUserManager,
            mockFeeManager
        );
        tradePair =
            TradePair(address(new TransparentUpgradeableProxy(address(tradePairImplementation), address(1), "")));

        vm.startPrank(UNLIMITED_OWNER);
        tradePair.initialize("Ethereum Trade Pair", collateral, mockPriceFeedAdapter, mockLiquidityPoolAdapter);

        // Configure
        tradePair.setLiquidatorReward(LIQUIDATOR_REWARD);
        tradePair.setMinLeverage(MIN_LEVERAGE);
        tradePair.setMaxLeverage(MAX_LEVERAGE);
        tradePair.setMinMargin(MIN_MARGIN);
        tradePair.setVolumeLimit(VOLUME_LIMIT);
        tradePair.setBorrowFeeRate(BASIS_BORROW_FEE_0);
        tradePair.setMaxFundingFeeRate(FUNDING_FEE_0);
        tradePair.setMaxExcessRatio(MAX_EXCESS_RATIO);
        tradePair.setFeeBufferFactor(BUFFER_FACTOR);
        tradePair.setTotalVolumeLimit(TOTAL_VOLUME_LIMIT);

        vm.stopPrank();
        vm.prank(ALICE);
        collateral.increaseAllowance(address(tradePair), 1_000_000 ether);
        // TradePair usually recieves collateral from the TradeManager
        // so we have to transfer it before opening a position
        dealTokens(address(tradePair), INITIAL_BALANCE);
    }
}
