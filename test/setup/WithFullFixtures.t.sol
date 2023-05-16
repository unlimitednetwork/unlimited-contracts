// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/price-feed/ChainlinkUsdPriceFeed.sol";
import "src/price-feed/PriceFeedAdapter.sol";
import "src/interfaces/IPriceFeedAdapter.sol";
import "src/interfaces/IController.sol";
import "src/trade-pair/TradePair.sol";
import "src/liquidity-pools/LiquidityPool.sol";
import "src/fee-manager/FeeManager.sol";
import "src/trade-manager/TradeManager.sol";
import "src/liquidity-pools/LiquidityPoolAdapter.sol";
import "src/sys-controller/Controller.sol";
import "src/sys-controller/UnlimitedOwner.sol";
import "src/user-manager/UserManager.sol";

import "test/mocks/MockToken.sol";
import "test/mocks/MockPriceFeedAdapter.sol";
import "./Constants.sol";

/**
 * @notice Test fixtures help to simulate specific scenarios in test cases
 */
contract WithFullFixtures is Test {
    using PositionMaths for Position;

    IController public controller;
    IUserManager public userManager;
    ITradeManager public tradeManager;
    IFeeManager public feeManager;
    UnlimitedOwner unlimitedOwner;

    address internal constant WHITELABEL_ADDRESS = address(9);
    address internal constant STAKERS_ADDRESS = address(10);
    address internal constant DEV_ADDRESS = address(11);
    address internal constant INSURANCE_ADDRESS = address(12);

    /// @notice this function is necessary to exclude this contract from test coverage
    function testMock() public {}

    function _deployMainContracts() internal {
        controller = _deployController();
        address tradeManager_ = computeCreateAddress(address(this), vm.getNonce(address(this)) + 1);
        userManager = _deployUserManager(controller, ITradeManager(tradeManager_));

        tradeManager = _deployTradeManager(controller, userManager);
        feeManager = _deployFeeManager(controller, userManager);
    }

    function _deployController() internal returns (IController) {
        unlimitedOwner = new UnlimitedOwner();
        unlimitedOwner.initialize();

        Controller _controller = new Controller(unlimitedOwner);

        return _controller;
    }

    function _deployUserManager(IController _controller, ITradeManager _tradeManager) internal returns (IUserManager) {
        // To simplify tests, we use the same fee sizes for the first two tiers
        uint8[7] memory feeSizes = [10, 10, 8, 7, 6, 5, 4];
        uint32[6] memory volumes = [1_000_000, 10_000_000, 100_000_000, 250_000_000, 500_000_000, 1_000_000_000];

        UserManager _userManager = new UserManager(unlimitedOwner, _controller, _tradeManager);
        _userManager.initialize(feeSizes, volumes);

        return _userManager;
    }

    function _deployTradeManager(IController _controller, IUserManager _userManager) internal returns (ITradeManager) {
        TradeManager _tradeManager = new TradeManager(_controller, _userManager);
        return ITradeManager(_tradeManager);
    }

    function _deployFeeManager(IController _controller, IUserManager _userManager) internal returns (IFeeManager) {
        FeeManager _feeManager = new FeeManager(unlimitedOwner, _controller, _userManager);
        _feeManager.initialize(
            10_00, // 10% max payout
            STAKERS_ADDRESS,
            DEV_ADDRESS,
            INSURANCE_ADDRESS
        );
        return IFeeManager(_feeManager);
    }

    function _deployPriceFeed(IController _controller) internal returns (MockPriceFeedAdapter) {
        MockPriceFeedAdapter priceFeedAdapter =
            new MockPriceFeedAdapter("Mock Price Feed Adapter", ASSET_DECIMALS, COLLATERAL_DECIMALS);
        int256 price = int256(2_000 * (10 ** COLLATERAL_DECIMALS));
        priceFeedAdapter.setMarkPrices(price, price);

        _controller.addPriceFeed(address(priceFeedAdapter));

        return priceFeedAdapter;
    }

    function _deployLiquidityPool(IController _controller, IERC20Metadata collateral, string memory name)
        internal
        returns (ILiquidityPool)
    {
        LiquidityPool liquidityPool = new LiquidityPool(unlimitedOwner, collateral, _controller);

        liquidityPool.initialize(name, name, 0, 0, 0, 0);

        _controller.addLiquidityPool(address(liquidityPool));

        return liquidityPool;
    }

    function _deployLiquidityPoolAdapter(
        IController _controller,
        IFeeManager _feeManager,
        IERC20Metadata collateral,
        LiquidityPoolConfig[] memory liquidityConfig
    ) internal returns (ILiquidityPoolAdapter) {
        LiquidityPoolAdapter liquidityPoolAdapter =
            new LiquidityPoolAdapter(unlimitedOwner, _controller, address(_feeManager), collateral);

        liquidityPoolAdapter.initialize(FULL_PERCENT, liquidityConfig);

        _controller.addLiquidityPoolAdapter(address(liquidityPoolAdapter));

        return liquidityPoolAdapter;
    }

    function _deployTradePair(
        IController _controller,
        IUserManager _userManager,
        IFeeManager _feeManager,
        ITradeManager _tradeManager,
        IERC20Metadata collateral,
        IPriceFeedAdapter priceFeedAdapter,
        ILiquidityPoolAdapter liquidityPoolAdapter
    ) internal returns (ITradePair) {
        TradePair tradePair = new TradePair(unlimitedOwner,
            _tradeManager,
            _userManager,
            _feeManager
        );
        tradePair.initialize("Shit Coin Trade Pair", collateral, ASSET_DECIMALS, priceFeedAdapter, liquidityPoolAdapter);

        _controller.addTradePair(address(tradePair));

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
        tradePair.setTotalSizeLimit(TOTAL_ASSET_AMOUNT_LIMIT);

        return tradePair;
    }
}
