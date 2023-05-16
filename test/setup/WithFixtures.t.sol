// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "src/price-feed/ChainlinkUsdPriceFeed.sol";
import "src/price-feed/PriceFeedAdapter.sol";
import "src/interfaces/IPriceFeedAdapter.sol";
import "src/interfaces/IController.sol";
import "src/trade-pair/TradePair.sol";
import "src/liquidity-pools/LiquidityPool.sol";
import "src/trade-manager/TradeManager.sol";
import "src/liquidity-pools/LiquidityPoolAdapter.sol";
import "src/sys-controller/Controller.sol";
import "src/user-manager/UserManager.sol";
import "./Constants.sol";
import "test/mocks/MockV3Aggregator.sol";
import "test/mocks/MockToken.sol";
import "test/mocks/MockPriceFeedAdapter.sol";
import "test/mocks/MockFeeManager.sol";
import "test/mocks/MockLiquidityPoolAdapter.sol";
import "test/mocks/MockUnlimitedOwner.sol";
import "../../src/sys-controller/Controller.sol";

/**
 * @notice Test fixtures help to simulate specific scenarios in test cases
 */
contract WithFixtures is Test {
    using PositionMaths for Position;

    MockToken asset;
    MockToken collateral;
    MockUnlimitedOwner mockUnlimitedOwner;
    IPriceFeed assetPriceFeed;
    IPriceFeed collateralPriceFeed;
    MockV3Aggregator assetAggregator;
    MockV3Aggregator collateralAggregator;
    TradeManager tradeManager;
    Controller controller;
    TradePair tradePair;
    MockPriceFeedAdapter priceFeedAdapter;
    MockFeeManager feeManager;
    MockLiquidityPoolAdapter mockLiquidityPoolAdapter;
    LiquidityPoolAdapter liquidityPoolAdapter1;
    LiquidityPoolAdapter liquidityPoolAdapter2;
    LiquidityPool liquidityPool1;
    LiquidityPool liquidityPool2;
    UserManager userManager;

    /// @notice this function is necessary to exclude this contract from test coverage
    function testMock() public {}

    function deployController() public {
        mockUnlimitedOwner = new MockUnlimitedOwner();
        mockUnlimitedOwner.setOwner(UNLIMITED_OWNER);

        controller = new Controller(mockUnlimitedOwner);

        // Also deploy UserManager
        uint8[7] memory feeSizes = [BASE_USER_FEE, 9, 8, 7, 6, 5, 4];
        uint32[6] memory volumes = [1_000_000, 10_000_000, 100_000_000, 250_000_000, 500_000_000, 1_000_000_000];

        userManager = new UserManager(mockUnlimitedOwner, controller);
        userManager.initialize(feeSizes, volumes);
    }

    function deployTokens() public {
        asset = new MockToken();
        collateral = new MockToken();
    }

    function deployPriceFeed() public {
        priceFeedAdapter = new MockPriceFeedAdapter("Mock Price Feed Adapter", ASSET_DECIMALS, COLLATERAL_DECIMALS);
        priceFeedAdapter.setMarkPrices(ASSET_PRICE_0, ASSET_PRICE_0);

        controller.addPriceFeed(address(priceFeedAdapter));
    }

    function deployTradePair() public {
        feeManager = new MockFeeManager();
        tradeManager = new TradeManager(controller, userManager);
        mockLiquidityPoolAdapter = new MockLiquidityPoolAdapter(collateral);
        mockLiquidityPoolAdapter.setRemainingVolume(REMAINING_VOLUME_0);

        // Deploy TradePair at timestamp 0 to make fee calculations easier
        vm.warp(0);
        tradePair = new TradePair(
            mockUnlimitedOwner,
            tradeManager,
            userManager,
            feeManager
        );

        tradePair.initialize(
            "Shit Coin Trade Pair", collateral, ASSET_DECIMALS, priceFeedAdapter, mockLiquidityPoolAdapter
        );

        tradePair.setLiquidatorReward(LIQUIDATOR_REWARD);
        tradePair.setMinLeverage(MIN_LEVERAGE);
        tradePair.setMaxLeverage(MAX_LEVERAGE);
        tradePair.setMinMargin(MIN_MARGIN);
        tradePair.setVolumeLimit(VOLUME_LIMIT);
        tradePair.setBorrowFeeRate(BASIS_BORROW_FEE_0);
        tradePair.setMaxFundingFeeRate(FUNDING_FEE_0);
        tradePair.setMaxExcessRatio(MAX_EXCESS_RATIO);
        tradePair.setTotalSizeLimit(TOTAL_ASSET_AMOUNT_LIMIT);

        controller.addLiquidityPoolAdapter(address(mockLiquidityPoolAdapter));
        controller.addTradePair(address(tradePair));
    }

    function dealTokens() public {
        deal(address(collateral), address(ALICE), INITIAL_BALANCE);
        vm.prank(ALICE);
        collateral.approve(address(tradeManager), INITIAL_BALANCE);
    }

    function deployContracts() public {
        vm.startPrank(UNLIMITED_OWNER);
        deployController();
        deployTokens();
        deployPriceFeed();
        deployTradePair();
        vm.stopPrank();

        dealTokens();
    }
}
