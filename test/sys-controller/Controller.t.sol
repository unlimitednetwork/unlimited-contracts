// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "test/setup/WithMocks.t.sol";
import "test/setup/Constants.sol";
import "src/sys-controller/Controller.sol";

contract ControllerTest is Test, WithMocks {
    IController controller;

    function setUp() public {
        controller = new Controller(mockUnlimitedOwner);

        mockTradePair.setPriceFeedAdapter(mockPriceFeedAdapter);
        mockTradePair.setLiquidityPoolAdapter(mockLiquidityPoolAdapter);

        vm.startPrank(UNLIMITED_OWNER);
    }

    function testAddTradePair() public {
        assertFalse(controller.isTradePair(address(mockTradePair)));

        // Invalid price feed and liq.pool adapter
        vm.expectRevert("Controller::_onlyActiveLiquidityPoolAdapter: invalid liquidity pool adapter.");
        controller.addTradePair(address(mockTradePair));

        controller.addLiquidityPoolAdapter(address(mockLiquidityPoolAdapter));

        // Invalid price feed
        vm.expectRevert("Controller::_onlyActivePriceFeed: invalid price feed.");

        controller.addTradePair(address(mockTradePair));
        controller.addPriceFeed(address(mockPriceFeedAdapter));
        controller.addTradePair(address(mockTradePair));

        assertTrue(controller.isTradePair(address(mockTradePair)));
    }

    function testAddLiquidityPool() public {
        assertFalse(controller.isLiquidityPool(address(10)));

        controller.addLiquidityPool(address(10));

        assertTrue(controller.isLiquidityPool(address(10)));
    }

    function testAddLiquidityPoolAdapter() public {
        assertFalse(controller.isLiquidityPoolAdapter(address(11)));

        controller.addLiquidityPoolAdapter(address(11));

        assertTrue(controller.isLiquidityPoolAdapter(address(11)));
    }

    function testAddPriceFeed() public {
        assertFalse(controller.isPriceFeed(address(12)));

        controller.addPriceFeed(address(12));

        assertTrue(controller.isPriceFeed(address(12)));
    }

    function testRemoveInactiveTradePair() public {
        vm.expectRevert("Controller::_onlyActiveTradePair: invalid trade pair.");
        controller.removeTradePair(address(100));
    }

    function testRemoveInactiveLiquidityPool() public {
        vm.expectRevert("Controller::_onlyActiveLiquidityPool: invalid liquidity pool.");
        controller.removeLiquidityPool(address(100));
    }

    function testRemoveInactiveLiquidityPoolAdapter() public {
        vm.expectRevert("Controller::_onlyActiveLiquidityPoolAdapter: invalid liquidity pool adapter.");
        controller.removeLiquidityPoolAdapter(address(100));
    }

    function testRemoveInactivePriceFeed() public {
        vm.expectRevert("Controller::_onlyActivePriceFeed: invalid price feed.");
        controller.removePriceFeed(address(100));
    }

    function testRemoveTradePair() public {
        controller.addPriceFeed(address(mockPriceFeedAdapter));
        controller.addLiquidityPoolAdapter(address(mockLiquidityPoolAdapter));
        controller.addTradePair(address(mockTradePair));
        controller.removeTradePair(address(mockTradePair));

        assertFalse(controller.isTradePair(address(mockTradePair)));
    }

    function testRemoveLiquidityPool() public {
        controller.addLiquidityPool(address(10));
        controller.removeLiquidityPool(address(10));
        assertFalse(controller.isLiquidityPool(address(10)));
    }

    function testRemoveLiquidityPoolAdapter() public {
        controller.addLiquidityPoolAdapter(address(11));
        controller.removeLiquidityPoolAdapter(address(11));
        assertFalse(controller.isLiquidityPoolAdapter(address(11)));
    }

    function testRemovePriceFeed() public {
        controller.addPriceFeed(address(12));
        controller.removePriceFeed(address(12));
        assertFalse(controller.isPriceFeed(address(12)));
    }

    function testAddUpdatable() public {
        // ACT
        controller.addUpdatable(address(13));

        // ASSERT
        assertTrue(controller.isUpdatable(address(13)));
    }

    function testRemoveUpdatable() public {
        // ARRANGE
        controller.addUpdatable(address(13));

        // ACT
        controller.removeUpdatable(address(13));

        // ASSERT
        assertFalse(controller.isUpdatable(address(13)));
    }

    function testAddSigner() public {
        // ACT
        controller.addSigner(address(14));

        // ASSERT
        assertTrue(controller.isSigner(address(14)));
    }

    function testRemoveSigner() public {
        // ARRANGE
        controller.addSigner(address(14));

        // ACT
        controller.removeSigner(address(14));

        // ASSERT
        assertFalse(controller.isSigner(address(14)));
    }

    function testAddOrderExecutor() public {
        // ACT
        controller.addOrderExecutor(address(15));

        // ASSERT
        assertTrue(controller.isOrderExecutor(address(15)));
    }

    function testRemoveOrderExecutor() public {
        // ARRANGE
        controller.addOrderExecutor(address(15));

        // ACT
        controller.removeOrderExecutor(address(15));

        // ASSERT
        assertFalse(controller.isOrderExecutor(address(15)));
    }

    function testOrderRewardOfCollateral() public {
        // ARRANGE
        uint256 expected = 100;

        // ACT
        controller.setOrderRewardOfCollateral(address(collateral), expected);

        // ASSERT
        assertEq(controller.orderRewardOfCollateral(address(collateral)), expected);
    }
}
