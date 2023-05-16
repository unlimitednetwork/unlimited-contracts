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
import "src/trade-manager/TradeManagerOrders.sol";
import "src/liquidity-pools/LiquidityPoolAdapter.sol";
import "src/sys-controller/Controller.sol";
import "src/sys-controller/UnlimitedOwner.sol";
import "src/user-manager/UserManager.sol";

import "test/mocks/MockV3Aggregator.sol";
import "test/mocks/MockArbSys.sol";
import "test/mocks/MockToken.sol";
import "test/mocks/MockPriceFeedAdapter.sol";
import "script/Deploy.s.sol";
import "script/config/testnet.sol";

// Constants for e2e tests:

uint256 constant MARGIN_0 = 1_000_000 * 1e6;
uint256 constant VOLUME_0 = 5000_000 * 1e6;

address constant ALICE = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
uint256 constant ALICE_PK = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
address constant BOB = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
uint256 constant BOB_PK = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;
uint256 constant LEVERAGE_0 = 5 * LEVERAGE_MULTIPLIER;
uint256 constant ASSET_AMOUNT_0 = 250 * ASSET_MULTIPLIER;
uint256 constant OPEN_POSITION_FEE_0 = VOLUME_0 * 10 / 100_00;
uint256 constant INITIAL_BALANCE = MARGIN_0 + OPEN_POSITION_FEE_0;
int256 constant BTC_PRICE = 20_000 * int256(PRICE_MULTIPLIER);

/**
 * @notice Test fixtures help to simulate specific scenarios in test cases
 */
contract WithDeployment is Helper, Test {
    UpdateData[] emptyUpdateData;
    IERC20Metadata collateral;
    ITradeManagerOrders tradeManager;
    IController controller;
    ITradePair tradePairBtc;
    ILiquidityPool liquidityPoolBluechip;
    ILiquidityPool liquidityPoolAltcoin;
    uint256 liquidityAmount;
    uint256 positionId;

    uint256 constant SIGNER_PK = 999;

    address orderExecutor;

    bytes32 private constant _TYPE_HASH_EIP712_DOMAIN =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /// @notice this function is necessary to exclude this contract from test coverage
    function testMock() public {}

    function _deploy() internal {
        vm.warp(1 hours);

        // Deploy an ERC20 token to the collateral address
        vm.etch(_getConstant("COLLATERAL"), address(new MockToken()).code);

        _deployMockPriceFeeds();

        DeployScript deployScript = new DeployScript();
        deployScript.setNetwork(_network);
        deployScript.run();

        // Set variables to be used in tests and helper functions
        controller = IController(_getAddress("controller"));
        collateral = IERC20Metadata(_getAddress("collateral"));
        tradeManager = TradeManagerOrders(_getAddress("tradeManagerOrders"));
        orderExecutor = _getConstant("ORDER_EXECUTOR");
        tradePairBtc = ITradePair(_getAddress("tradePairBTC"));
        liquidityPoolBluechip = ILiquidityPool(_getAddress("liquidityPoolBluechip"));
        liquidityPoolAltcoin = ILiquidityPool(_getAddress("liquidityPoolAltcoin"));

        // TEST CONFIGURATION
        vm.prank(vm.addr(vm.envUint("DEPLOYER")));
        controller.addSigner(vm.addr(SIGNER_PK));

        // ADD LIQUIDITY
        liquidityAmount = 100_000 * COLLATERAL_MULTIPLIER;
        deal(address(collateral), ALICE, liquidityAmount);

        _depositLiquidity("liquidityPoolBluechip", ALICE, liquidityAmount);

        _updatePrice("BTC", BTC_PRICE);

        // Setup Arbitrum environment
        vm.etch(address(100), address(new MockArbSys()).code);
    }

    function _deployMockPriceFeeds() internal {
        AggregatorV3Interface ethPriceFeed = new MockV3Aggregator(8, 1_600*1e8);
        vm.etch(_getConstant(_network, "CHAINLINK_ETH"), address(ethPriceFeed).code);
        MockV3Aggregator(_getConstant(_network, "CHAINLINK_ETH")).updateAnswer(1_600 * 1e8);

        AggregatorV3Interface btcPriceFeed = new MockV3Aggregator(8, BTC_PRICE * 1e8 / int256(PRICE_MULTIPLIER));
        vm.etch(_getConstant(_network, "CHAINLINK_BTC"), address(btcPriceFeed).code);
        MockV3Aggregator(_getConstant(_network, "CHAINLINK_BTC")).updateAnswer(
            BTC_PRICE * 1e8 / int256(PRICE_MULTIPLIER)
        );

        AggregatorV3Interface linkPriceFeed = new MockV3Aggregator(8, 600*1e8);
        vm.etch(_getConstant(_network, "CHAINLINK_LINK"), address(linkPriceFeed).code);
        MockV3Aggregator(_getConstant(_network, "CHAINLINK_LINK")).updateAnswer(600 * 1e8);

        AggregatorV3Interface usdcPriceFeed = new MockV3Aggregator(8, 1*1e8);
        vm.etch(_getConstant(_network, "CHAINLINK_USDC"), address(usdcPriceFeed).code);
        MockV3Aggregator(_getConstant(_network, "CHAINLINK_USDC")).updateAnswer(1 * 1e8);
    }

    /* ========= HELPER FUNCTIONS ========= */

    function _updatePrice(string memory assetName, int256 price_) internal {
        uint256 signerPk = 999;
        address signer = vm.addr(signerPk);

        // Update Chainlink Aggregator with correct decimals
        MockV3Aggregator(_getConstant(string.concat("CHAINLINK_", assetName))).updateAnswer(
            price_ * 1e8 / int256(PRICE_MULTIPLIER)
        );

        // Update UnlimitedPriceFeedAdapter
        IPriceFeedAdapter priceFeedAdapter =
            IPriceFeedAdapter(_getAddress(string.concat("priceFeedAdapter", assetName)));
        bytes32 domainSeparator = keccak256(
            abi.encode(
                _TYPE_HASH_EIP712_DOMAIN,
                keccak256(bytes(priceFeedAdapter.name())),
                keccak256(bytes("1")),
                block.chainid,
                address(priceFeedAdapter)
            )
        );
        PriceData memory priceData = PriceData(uint32(block.timestamp), uint32(block.timestamp + 60), int192(price_));
        bytes32 priceDataHash = keccak256(abi.encode(address(priceFeedAdapter), priceData));
        bytes32 typedDataHash = ECDSA.toTypedDataHash(domainSeparator, priceDataHash);
        bytes memory signature = _sign(signerPk, typedDataHash);
        bytes memory updateData = abi.encodePacked(signature, abi.encode(signer), abi.encode(priceData));
        IUpdatable(address(priceFeedAdapter)).update(updateData);
    }

    function _openPosition(
        uint256 userPrivateKey_,
        string memory assetName_,
        uint256 margin_,
        uint256 leverage_,
        bool isShort_
    ) internal returns (uint256) {
        ITradePair _tradePair = ITradePair(_getAddress(string.concat("tradePair", assetName_)));
        OpenPositionOrder memory openPositionOrder = OpenPositionOrder(
            OpenPositionParams(address(_tradePair), margin_, leverage_, isShort_, address(0), address(0)),
            Constraints(block.timestamp + 1 hours, 0, type(int192).max),
            0
        );

        bytes memory signature = _sign(userPrivateKey_, tradeManager.hash(openPositionOrder));

        vm.startPrank(vm.addr(userPrivateKey_));
        _tradePair.collateral().approve(address(tradeManager), margin_ + ORDER_REWARD);
        vm.stopPrank();

        vm.prank(orderExecutor);
        return tradeManager.openPositionViaSignature(
            openPositionOrder, emptyUpdateData, vm.addr(userPrivateKey_), signature
        );
    }

    function _closePosition(uint256 userPrivateKey_, string memory assetName_, uint256 positionId_) internal {
        ITradePair _tradePair = ITradePair(_getAddress(string.concat("tradePair", assetName_)));

        ClosePositionOrder memory closePositionOrder = ClosePositionOrder(
            ClosePositionParams(address(_tradePair), positionId_),
            Constraints(block.timestamp + 1 hours, 0, type(int192).max),
            0,
            0
        );

        bytes32 orderHash = tradeManager.hash(closePositionOrder);
        bytes memory signature = _sign(userPrivateKey_, orderHash);

        vm.prank(orderExecutor);
        tradeManager.closePositionViaSignature(closePositionOrder, emptyUpdateData, vm.addr(userPrivateKey_), signature);
    }

    function _partiallyClosePosition(
        uint256 userPrivateKey_,
        string memory assetName_,
        uint256 positionId_,
        uint256 proportion_
    ) internal {
        ITradePair _tradePair = ITradePair(_getAddress(string.concat("tradePair", assetName_)));

        PartiallyClosePositionOrder memory partiallyClosePositionOrder = PartiallyClosePositionOrder(
            PartiallyClosePositionParams(address(_tradePair), positionId_, proportion_),
            Constraints(block.timestamp + 1 hours, 0, type(int192).max),
            0,
            0
        );

        bytes32 orderHash = tradeManager.hashPartiallyClosePositionOrder(partiallyClosePositionOrder);
        bytes memory signature = _sign(userPrivateKey_, orderHash);

        vm.prank(orderExecutor);
        tradeManager.partiallyClosePositionViaSignature(
            partiallyClosePositionOrder, emptyUpdateData, vm.addr(userPrivateKey_), signature
        );
    }

    function _addMarginToPosition(
        uint256 userPrivateKey_,
        string memory assetName_,
        uint256 positionId_,
        uint256 addedMargin_
    ) internal {
        ITradePair _tradePair = ITradePair(_getAddress(string.concat("tradePair", assetName_)));
        AddMarginToPositionOrder memory addMarginToPositionOrder = AddMarginToPositionOrder(
            AddMarginToPositionParams(address(_tradePair), positionId_, addedMargin_),
            Constraints(block.timestamp + 1 hours, 0, type(int192).max),
            0,
            0
        );

        bytes32 orderHash = tradeManager.hashAddMarginToPositionOrder(addMarginToPositionOrder);
        bytes memory signature = _sign(userPrivateKey_, orderHash);

        vm.startPrank(vm.addr(userPrivateKey_));
        _tradePair.collateral().approve(address(tradeManager), addedMargin_ + ORDER_REWARD);
        vm.stopPrank();

        vm.prank(orderExecutor);
        tradeManager.addMarginToPositionViaSignature(
            addMarginToPositionOrder, emptyUpdateData, vm.addr(userPrivateKey_), signature
        );
    }

    function _removeMarginFromPosition(
        uint256 userPrivateKey_,
        string memory assetName_,
        uint256 positionId_,
        uint256 removedMargin_
    ) internal {
        ITradePair _tradePair = ITradePair(_getAddress(string.concat("tradePair", assetName_)));

        RemoveMarginFromPositionOrder memory removeMarginFromPositionOrder = RemoveMarginFromPositionOrder(
            RemoveMarginFromPositionParams(address(_tradePair), positionId_, removedMargin_),
            Constraints(block.timestamp + 1 hours, 0, type(int192).max),
            0,
            0
        );

        bytes32 orderHash = tradeManager.hashRemoveMarginFromPositionOrder(removeMarginFromPositionOrder);
        bytes memory signature = _sign(userPrivateKey_, orderHash);

        vm.prank(orderExecutor);
        tradeManager.removeMarginFromPositionViaSignature(
            removeMarginFromPositionOrder, emptyUpdateData, vm.addr(userPrivateKey_), signature
        );
    }

    function _extendPosition(
        uint256 userPrivateKey_,
        string memory assetName_,
        uint256 positionId_,
        uint256 addedMargin_,
        uint256 addedLeverage_
    ) internal {
        ITradePair _tradePair = ITradePair(_getAddress(string.concat("tradePair", assetName_)));

        ExtendPositionOrder memory extendPositionOrder = ExtendPositionOrder(
            ExtendPositionParams(address(_tradePair), positionId_, addedMargin_, addedLeverage_),
            Constraints(block.timestamp + 1 hours, 0, type(int192).max),
            0,
            0
        );

        bytes32 orderHash = tradeManager.hashExtendPositionOrder(extendPositionOrder);
        bytes memory signature = _sign(userPrivateKey_, orderHash);

        vm.startPrank(vm.addr(userPrivateKey_));
        _tradePair.collateral().approve(address(tradeManager), addedMargin_ + ORDER_REWARD);
        vm.stopPrank();

        vm.prank(orderExecutor);
        tradeManager.extendPositionViaSignature(
            extendPositionOrder, emptyUpdateData, vm.addr(userPrivateKey_), signature
        );
    }

    function _extendPositionToLeverage(
        uint256 userPrivateKey_,
        string memory assetName_,
        uint256 positionId_,
        uint256 targetLeverage_
    ) internal {
        ITradePair _tradePair = ITradePair(_getAddress(string.concat("tradePair", assetName_)));

        ExtendPositionToLeverageOrder memory extendPositionToLeverageOrder = ExtendPositionToLeverageOrder(
            ExtendPositionToLeverageParams(address(_tradePair), positionId_, targetLeverage_),
            Constraints(block.timestamp + 1 hours, 0, type(int192).max),
            0,
            0
        );

        bytes32 orderHash = tradeManager.hashExtendPositionToLeverageOrder(extendPositionToLeverageOrder);
        bytes memory signature = _sign(userPrivateKey_, orderHash);

        vm.prank(orderExecutor);
        tradeManager.extendPositionToLeverageViaSignature(
            extendPositionToLeverageOrder, emptyUpdateData, vm.addr(userPrivateKey_), signature
        );
    }

    function _depositLiquidity(string memory liquidityPool, address user, uint256 amount)
        internal
        prank(user)
        returns (uint256 shares)
    {
        ILiquidityPool _liquidityPool = ILiquidityPool(_getAddress(liquidityPool));
        collateral.approve(address(_liquidityPool), amount);
        shares = _liquidityPool.deposit(amount, 0);
    }

    modifier prank(address executor_) {
        vm.startPrank(executor_);
        _;
        vm.stopPrank();
    }
}
