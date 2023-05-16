// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "forge-std/Test.sol";

import "test/mocks/MockArbSys.sol";
import "test/mocks/MockToken.sol";
import "test/mocks/MockUnlimitedOwner.sol";
import "test/mocks/MockPriceFeedAdapter.sol";
import "test/mocks/MockPriceFeed.sol";
import "test/mocks/MockLiquidityPoolAdapter.sol";
import "test/mocks/MockLiquidityPool.sol";
import "test/mocks/MockFeeManager.sol";
import "test/mocks/MockV3Aggregator.sol";
import "test/mocks/MockTradeManager.sol";
import "test/mocks/MockUserManager.sol";
import "test/mocks/MockTradePair.sol";
import "test/mocks/MockController.sol";

import "./Constants.sol";

contract WithMocks is Test {
    MockToken collateral;
    MockUnlimitedOwner mockUnlimitedOwner;
    MockPriceFeedAdapter mockPriceFeedAdapter;
    MockPriceFeed mockPriceFeed;
    MockFeeManager mockFeeManager;
    MockLiquidityPoolAdapter mockLiquidityPoolAdapter;
    MockLiquidityPool mockLiquidityPool;
    MockTradeManager mockTradeManager;
    MockUserManager mockUserManager;
    MockTradePair mockTradePair;
    MockController mockController;

    /// @notice this function is necessary to exclude this contract from test coverage
    function testMock() public virtual {}

    constructor() {
        collateral = new MockToken();
        collateral.setDecimals(8);
        mockUnlimitedOwner = new MockUnlimitedOwner();
        mockUnlimitedOwner.setOwner(UNLIMITED_OWNER);
        mockPriceFeedAdapter = new MockPriceFeedAdapter("Mock Price Feed Adapter", ASSET_DECIMALS, COLLATERAL_DECIMALS);
        mockPriceFeed = new MockPriceFeed(ASSET_PRICE_0);
        mockPriceFeedAdapter.setMarkPrices(ASSET_PRICE_0, ASSET_PRICE_0);
        mockFeeManager = new MockFeeManager();
        mockLiquidityPoolAdapter = new MockLiquidityPoolAdapter(collateral);
        mockLiquidityPool = new MockLiquidityPool(collateral);
        mockTradeManager = new MockTradeManager();
        mockUserManager = new MockUserManager();
        mockTradePair = new MockTradePair();
        mockTradePair.setCollateral(collateral);
        mockController = new MockController();

        // Setup Arbitrum environment
        vm.etch(address(100), address(new MockArbSys()).code);
    }

    function dealTokens(address toAddress, uint256 amount) public {
        deal(address(collateral), toAddress, amount);
    }
}
