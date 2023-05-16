// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "src/interfaces/ILiquidityPool.sol";

/**
 * @notice used for tests
 */
contract MockLiquidityPool is ILiquidityPool {
    using SafeERC20 for IERC20;

    /// @notice this function is necessary to exclude this contract from test coverage
    function testMock() public {}

    uint256 public availableLiquidity;
    IERC20 collateral;

    constructor(IERC20 _collateral) {
        collateral = _collateral;
    }

    function setAvailableLiquidity(uint256 _availableLiquidity) public {
        availableLiquidity = _availableLiquidity;
    }

    function canTransferLps(address user) external view returns (bool) {}

    function canWithdrawLps(address user) external view returns (bool) {}

    function userWithdrawalFee(address user) external view returns (uint256) {}

    function deposit(uint256 amount, uint256 minOut) external returns (uint256) {}

    function withdraw(uint256 lpAmount, uint256 minOut) external returns (uint256) {}

    function earlyWithdraw(uint256 lpAmount, uint256 minOut) external returns (uint256) {}

    function depositAndLock(uint256 amount, uint256 minOut, uint256 poolId) external returns (uint256) {}

    function syncUserDeposits(address user) external {}

    function previewPoolsOf(address) external pure returns (UserPoolDetails[] memory) {
        UserPoolDetails[] memory pools = new UserPoolDetails[](1);
        return pools;
    }

    function previewRedeemPoolShares(uint256, uint256) external pure returns (uint256) {
        return 0;
    }

    function requestLossPayout(uint256 loss) external {
        collateral.safeTransfer(msg.sender, loss);
    }

    function depositProfit(uint256 profit) external {
        collateral.safeTransferFrom(msg.sender, address(this), profit);
    }

    function depositFees(uint256 fee) external {
        collateral.safeTransferFrom(msg.sender, address(this), fee);
    }

    function addPool(uint40, uint16) external pure returns (uint256) {
        return 0;
    }

    function updatePool(uint256 poolId_, uint40 lockTime_, uint16 multiplier_) external {}

    function updateDefaultLockTime(uint256 defaultLockTime) external {}

    function updateEarlyWithdrawalFee(uint256 earlyWithdrawalFee) external {}

    function updateEarlyWithdrawalTime(uint256 earlyWithdrawalTime) external {}

    function updateMinimumAmount(uint256 minimumAmount) external {}
}
