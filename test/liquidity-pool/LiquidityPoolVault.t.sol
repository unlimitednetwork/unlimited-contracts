// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "src/price-feed/ChainlinkUsdPriceFeed.sol";
import "test/mocks/MockV3Aggregator.sol";
import "../setup/WithMocks.t.sol";
import "../mocks/MockController.sol";
import "src/liquidity-pools/LiquidityPool.sol";

contract LiquidityPoolVaultTest is Test, WithMocks {
    // IController private controller;
    LiquidityPool private liquidityPool;

    function setUp() public {
        ILiquidityPool liquidityPoolImplementation = new LiquidityPool(
            mockUnlimitedOwner,
            collateral,
            mockController
        );

        liquidityPool = LiquidityPool(
            address(new TransparentUpgradeableProxy(address(liquidityPoolImplementation), address(1), ""))
        );

        vm.prank(UNLIMITED_OWNER);
        liquidityPool.initialize("Test LP", "TLPS", 0, 0, 0, 0);

        deal(address(collateral), ALICE, 100_000 ether, true);
        deal(address(collateral), BOB, 100_000 ether, true);
        deal(address(collateral), CAROL, 100_000 ether, true);
        deal(address(collateral), DAN, 100_000 ether, true);
        deal(address(collateral), address(mockLiquidityPoolAdapter), 100_000 ether, true);
    }

    function testLines() public {}
}
