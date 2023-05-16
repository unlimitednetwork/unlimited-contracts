// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "src/interfaces/IController.sol";

contract MockController is IController {
    bool public paused;

    /// @notice this function is necessary to exclude this contract from test coverage
    function testMock() public {}

    function isTradePair(address) external pure override returns (bool) {
        return true;
    }

    function isLiquidityPool(address) external pure override returns (bool) {
        return true;
    }

    function isLiquidityPoolAdapter(address) external pure override returns (bool) {
        return true;
    }

    function isPriceFeed(address) external pure override returns (bool) {
        return true;
    }

    function isSigner(address) external pure override returns (bool) {
        return true;
    }

    function isUpdatable(address) external pure override returns (bool) {
        return true;
    }

    function isOrderExecutor(address) external pure override returns (bool) {
        return true;
    }

    function orderRewardOfCollateral(address) external pure returns (uint256) {
        return 0;
    }

    function checkTradePairActive(address) external view {}

    function pause() external {}

    function unpause() external {}

    function addTradePair(address) external {}

    function addLiquidityPool(address) external {}

    function addLiquidityPoolAdapter(address) external {}

    function addPriceFeed(address) external {}

    function addUpdatable(address) external {}

    function addSigner(address) external {}

    function addOrderExecutor(address) external {}

    function removeTradePair(address) external {}

    function removeLiquidityPool(address) external {}

    function removeLiquidityPoolAdapter(address) external {}

    function removePriceFeed(address) external {}

    function removeUpdatable(address) external {}

    function removeSigner(address) external {}

    function removeOrderExecutor(address) external {}

    function setOrderRewardOfCollateral(address, uint256) external {}
}
