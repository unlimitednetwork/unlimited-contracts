// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "src/interfaces/ILiquidityPoolAdapter.sol";

/**
 * @notice used for tests
 */
contract MockLiquidityPoolAdapter is ILiquidityPoolAdapter {
    using SafeERC20 for IERC20;

    /// @notice this function is necessary to exclude this contract from test coverage
    function testMock() public {}

    uint256 public remainingVolume;
    IERC20 collateral;
    uint256 public totalMarginLong;
    uint256 public totalLoanLong;
    uint256 public totalSizeLong;
    uint256 public totalMarginShort;
    uint256 public totalLoanShort;
    uint256 public totalSizeShort;

    constructor(IERC20 _collateral) {
        collateral = _collateral;
    }

    function name() external pure returns (string memory) {
        return "MockLiquidityPoolAdapter";
    }

    function availableLiquidity() public view returns (uint256) {
        return remainingVolume;
    }

    function setRemainingVolume(uint256 volume) public {
        remainingVolume = volume;
    }

    function requestLossPayout(uint256 profit) external returns (uint256 actualPayout) {
        uint256 _remainingVolume = collateral.balanceOf(address(this));
        actualPayout = profit;
        if (_remainingVolume < actualPayout) {
            actualPayout = _remainingVolume;
        }

        collateral.safeTransfer(msg.sender, actualPayout);
    }

    function depositProfit(uint256 profit) external {}

    function depositFees(uint256 fee) external {}
}
