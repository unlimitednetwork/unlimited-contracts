// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "src/price-feed/ChainlinkUsdPriceFeed.sol";
import "test/mocks/MockV3Aggregator.sol";
import "../setup/WithMocks.t.sol";
import "../mocks/MockController.sol";
import "src/liquidity-pools/LiquidityPool.sol";

contract LiquidityPoolTest is Test, WithMocks {
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

    function testDeposit() public {
        // ACT
        uint256 depositAmountAlice = 10 * 1e8;
        uint256 sharesAlice = _deposit(ALICE, depositAmountAlice);

        uint256 depositAmountBob = 20 * 1e8;
        uint256 sharesBob = _deposit(BOB, depositAmountBob);

        // ASSERT
        uint256 decimalsDiff = 10 ** (liquidityPool.decimals() - 8);
        assertEq(depositAmountAlice * decimalsDiff, sharesAlice);
        assertEq(depositAmountBob * decimalsDiff, sharesBob);
    }

    function testDeposit_testAfterProfit() public {
        // ARRANGE
        uint256 depositAmountAlice = 10 * 1e8;
        uint256 sharesAlice = _deposit(ALICE, depositAmountAlice);

        _depositProfit(depositAmountAlice);

        // ACT
        uint256 depositAmountBob = 20 * 1e8;
        uint256 sharesBob = _deposit(BOB, depositAmountBob);

        // ASSERT
        uint256 decimalsDiff = 10 ** (liquidityPool.decimals() - 8);
        assertEq(depositAmountAlice * decimalsDiff, sharesAlice);
        assertEq(sharesAlice, sharesBob);
    }

    function testWithdraw() public {
        // ARRANGE
        uint256 depositAmountAlice = 10 * 1e8;
        uint256 sharesAlice = _deposit(ALICE, depositAmountAlice);

        _depositProfit(depositAmountAlice);

        uint256 depositAmountBob = 20 * 1e8;
        uint256 sharesBob = _deposit(BOB, depositAmountBob);

        uint256 aliceBalanceBefore = collateral.balanceOf(ALICE);
        uint256 bobBalanceBefore = collateral.balanceOf(BOB);

        // ACT
        _withdraw(ALICE, sharesAlice);
        _withdraw(BOB, sharesBob);

        // ASSERT
        uint256 aliceBalanceAfter = collateral.balanceOf(ALICE);
        uint256 bobBalanceAfter = collateral.balanceOf(BOB);

        assertEq(aliceBalanceAfter - aliceBalanceBefore, depositAmountAlice * 2);
        assertEq(bobBalanceAfter - bobBalanceBefore, depositAmountBob);
    }

    function testDepositFees() public {
        // ARRANGE
        uint16 multiplier = uint16(FULL_PERCENT);
        _addPool(0, multiplier);

        uint256 depositAmountAlice = 10 * 1e8;
        uint256 sharesAlice = _deposit(ALICE, depositAmountAlice);

        uint256 depositAmountBob = depositAmountAlice;
        _depositAndLock(BOB, depositAmountBob, 0);

        uint256 depositFeesAmount = 30 * 1e8;
        _depositFees(depositFeesAmount);

        uint256 aliceBalanceBefore = collateral.balanceOf(ALICE);
        uint256 bobBalanceBefore = collateral.balanceOf(BOB);

        // ACT
        _withdraw(ALICE, sharesAlice);
        _withdrawFromPool(BOB, 0, type(uint256).max);

        // ASSERT
        uint256 aliceBalanceAfter = collateral.balanceOf(ALICE);
        uint256 bobBalanceAfter = collateral.balanceOf(BOB);

        assertEq(aliceBalanceAfter - aliceBalanceBefore, depositAmountAlice + (depositFeesAmount / 3));
        assertEq(bobBalanceAfter - bobBalanceBefore, depositAmountBob + (depositFeesAmount * 2 / 3));
    }

    function testDepositFees_twice() public {
        // ARRANGE
        uint16 multiplier = uint16(FULL_PERCENT);
        _addPool(0, multiplier);

        uint256 depositAmountAlice = 10 * 1e8;
        uint256 sharesAlice = _deposit(ALICE, depositAmountAlice);

        uint256 depositAmountBob = depositAmountAlice;
        _depositAndLock(BOB, depositAmountBob, 0);

        uint256 depositFeesAmountFirst = 30 * 1e8;
        _depositFees(depositFeesAmountFirst);

        uint256 depositFeesAmountSecond = 40 * 1e8;
        _depositFees(depositFeesAmountSecond);

        uint256 aliceBalanceBefore = collateral.balanceOf(ALICE);
        uint256 bobBalanceBefore = collateral.balanceOf(BOB);

        // ACT
        _withdraw(ALICE, sharesAlice);
        _withdrawFromPool(BOB, 0, type(uint256).max);

        // ASSERT
        uint256 aliceBalanceAfter = collateral.balanceOf(ALICE);
        uint256 bobBalanceAfter = collateral.balanceOf(BOB);

        assertEq(
            aliceBalanceAfter - aliceBalanceBefore,
            depositAmountAlice + (depositFeesAmountFirst / 3) + (depositFeesAmountSecond / 4)
        );
        assertEq(
            bobBalanceAfter - bobBalanceBefore,
            depositAmountBob + (depositFeesAmountFirst * 2 / 3) + (depositFeesAmountSecond * 3 / 4)
        );

        // assert liquidity pool
        assertEq(collateral.balanceOf(address(liquidityPool)), 0);
        assertEq(liquidityPool.balanceOf(address(liquidityPool)), 0);
        assertEq(liquidityPool.totalSupply(), 0);
        assertEq(liquidityPool.totalAssets(), 0);
    }

    function testMinimumAmount() public {
        // ARRANGE
        ILiquidityPool liquidityPoolImplementation = new LiquidityPool(
            mockUnlimitedOwner,
            collateral,
            mockController
        );

        liquidityPool = LiquidityPool(
            address(new TransparentUpgradeableProxy(address(liquidityPoolImplementation), address(1), ""))
        );

        uint256 minimumAmount = 1000;
        vm.prank(UNLIMITED_OWNER);
        liquidityPool.initialize("Test LP", "TLPS", 0, 0, 0, minimumAmount);
        _deposit(ALICE, minimumAmount / 2);
        assertEq(liquidityPool.availableLiquidity(), 0);
        _deposit(ALICE, minimumAmount / 2);
        assertEq(liquidityPool.availableLiquidity(), 0);

        // Only when the minimum amount is reached, deposits count as available liquidity

        _deposit(ALICE, minimumAmount / 2);
        assertEq(liquidityPool.availableLiquidity(), minimumAmount / 2);
    }

    function testUpdatePool() public {
        // ARRANGE
        uint16 multiplier = uint16(FULL_PERCENT);
        _addPool(0, 0);

        // ACT
        _updatePool(0, 1 hours, multiplier);

        // ASSERT
        (uint256 poolLockTime, uint256 poolMultiplier,,) = liquidityPool.pools(0);
        assertEq(poolLockTime, 1 hours);
        assertEq(poolMultiplier, multiplier);
    }

    function testUpdatePoolZeroLocktime() public {
        // ARRANGE
        uint16 multiplier = uint16(FULL_PERCENT);
        _addPool(1 hours, 0);

        // ACT
        _updatePool(0, 0, multiplier);

        // ASSERT
        (uint256 poolLockTime, uint256 poolMultiplier,,) = liquidityPool.pools(0);
        assertEq(poolLockTime, 1 hours);
        assertEq(poolMultiplier, multiplier);
    }

    function testUpdatePoolZeroMultiplier() public {
        // ARRANGE
        uint16 multiplier = uint16(FULL_PERCENT);
        _addPool(0, multiplier);

        // ACT
        _updatePool(0, 1 hours, 0);

        // ASSERT
        (uint256 poolLockTime, uint256 poolMultiplier,,) = liquidityPool.pools(0);
        assertEq(poolLockTime, 1 hours);
        assertEq(poolMultiplier, multiplier);
    }

    function testUpdatePoolZeroLocktimeZeroMultiplier() public {
        // ARRANGE
        uint16 multiplier = uint16(FULL_PERCENT);
        _addPool(1 hours, multiplier);

        // ACT
        _updatePool(0, 0, 0);

        // ASSERT
        (uint256 poolLockTime, uint256 poolMultiplier,,) = liquidityPool.pools(0);
        assertEq(poolLockTime, 0);
        assertEq(poolMultiplier, 0);
    }

    function testLockLps() public {
        // ARRANGE
        uint16 multiplier = uint16(FULL_PERCENT);
        _addPool(0, multiplier);

        uint256 depositAmount = 10 * 1e8;
        uint256 shares = _deposit(ALICE, depositAmount);

        // ACT
        _lockShares(ALICE, shares, 0);

        // ASSERT
        (uint256 poolLockTime, uint256 poolMultiplier,,) = liquidityPool.pools(0);
        assertEq(poolLockTime, 0);
        assertEq(poolMultiplier, multiplier);
    }

    function testExitPool() public {
        // ARRANGE
        uint16 multiplier = uint16(FULL_PERCENT);
        _addPool(0, multiplier);

        uint256 depositAmountAlice = 10 * 1e8;
        uint256 sharesAlice = _depositAndLock(ALICE, depositAmountAlice, 0);
        (uint256 alicePoolShares,,,) = liquidityPool.userPoolInfo(0, ALICE);

        // ACT
        vm.prank(ALICE);
        liquidityPool.unlockShares(0, alicePoolShares);

        // ASSERT
        assertEq(liquidityPool.balanceOf(ALICE), sharesAlice);
    }

    function testCannotWithdrawZeroPoolShares() public {
        // ARRANGE
        uint16 multiplier = uint16(FULL_PERCENT);
        _addPool(0, multiplier);

        uint256 depositAmountAlice = 10 * 1e8;
        _depositAndLock(ALICE, depositAmountAlice, 0);

        // ACT & ASSERT
        vm.expectRevert("LiquidityPool::_unlockShares: Cannot withdraw zero shares");
        vm.prank(ALICE);
        liquidityPool.unlockShares(0, 0);
    }

    function testCannotWithDrawMorePoolShares() public {
        // ARRANGE
        uint16 multiplier = uint16(FULL_PERCENT);
        _addPool(0, multiplier);

        uint256 depositAmountAlice = 10 * 1e8;
        _depositAndLock(ALICE, depositAmountAlice, 0);
        (uint256 alicePoolShares,,,) = liquidityPool.userPoolInfo(0, ALICE);

        // ACT & ASSERT
        vm.expectRevert("LiquidityPool::_unlockShares: User does not have enough unlocked pool shares");
        vm.prank(ALICE);
        liquidityPool.unlockShares(0, alicePoolShares + 1);
    }

    function testLockPeriod() public {
        // ARRANGE
        vm.warp(0);
        uint16 multiplier = uint16(FULL_PERCENT);
        _addPool(1 hours, multiplier);

        uint256 depositAmountAlice = 10 * 1e8;
        _depositAndLock(ALICE, depositAmountAlice, 0);
        (uint256 alicePoolShares,,,) = liquidityPool.userPoolInfo(0, ALICE);

        // ACT & ASSERT
        vm.expectRevert("LiquidityPool::_unlockShares: User does not have enough unlocked pool shares");
        vm.prank(ALICE);
        liquidityPool.unlockShares(0, alicePoolShares);

        vm.warp(1 hours);
        vm.prank(ALICE);
        liquidityPool.unlockShares(0, alicePoolShares);

        (uint256 poolShares, uint256 unlockedPoolShares, uint128 nextIndex,) = liquidityPool.userPoolInfo(0, ALICE);
        assertEq(poolShares, 0);
        assertEq(unlockedPoolShares, 0);
        assertEq(nextIndex, 1);
    }

    function testMultipleLocks() public {
        // ARRANGE

        vm.warp(0);
        uint16 multiplier = uint16(FULL_PERCENT);
        _addPool(2 hours, multiplier);

        // ACT (lock twice)
        uint256 depositAmountAlice = 10 * 1e8;
        _depositAndLock(ALICE, depositAmountAlice, 0);

        vm.warp(1 hours);
        _depositAndLock(ALICE, depositAmountAlice, 0);

        (uint256 alicePoolShares,,,) = liquidityPool.userPoolInfo(0, ALICE);

        vm.warp(2 hours);

        vm.expectRevert("LiquidityPool::_unlockShares: User does not have enough unlocked pool shares");
        vm.prank(ALICE);
        liquidityPool.unlockShares(0, alicePoolShares);

        vm.warp(4 hours);

        vm.prank(ALICE);
        liquidityPool.unlockShares(0, alicePoolShares);

        (uint256 poolShares, uint256 unlockedPoolShares, uint128 nextIndex,) = liquidityPool.userPoolInfo(0, ALICE);
        assertEq(poolShares, 0);
        assertEq(unlockedPoolShares, 0);
        assertEq(nextIndex, 2);
    }

    function testConsecutiveUnlocks() public {
        // ARRANGE

        vm.warp(0);
        uint16 multiplier = uint16(FULL_PERCENT);
        _addPool(2 hours, multiplier);

        // ACT
        uint256 depositAmountAlice = 10 * 1e8;
        _depositAndLock(ALICE, depositAmountAlice, 0);
        (uint256 alicePoolShares,,,) = liquidityPool.userPoolInfo(0, ALICE);

        vm.warp(1 hours);
        _depositAndLock(ALICE, depositAmountAlice, 0);

        // After 2 hours only one lock should be unlocked
        vm.warp(2 hours);

        vm.expectRevert("LiquidityPool::_unlockShares: User does not have enough unlocked pool shares");
        vm.prank(ALICE);
        liquidityPool.unlockShares(0, alicePoolShares * 2);

        vm.prank(ALICE);
        liquidityPool.unlockShares(0, alicePoolShares);

        // After 3 hours the other lock should be unlocked
        vm.warp(3 hours);

        vm.prank(ALICE);
        liquidityPool.unlockShares(0, alicePoolShares);

        (uint256 poolShares, uint256 unlockedPoolShares, uint128 nextIndex,) = liquidityPool.userPoolInfo(0, ALICE);
        assertEq(poolShares, 0);
        assertEq(unlockedPoolShares, 0);
        assertEq(nextIndex, 2);
    }

    function testMultipleConsecutiveLocks() public {
        // ARRANGE
        vm.warp(0);
        uint16 multiplier = uint16(FULL_PERCENT);
        _addPool(2 hours, multiplier);

        // ACT
        uint256 depositAmountAlice = 10 * 1e8;
        _depositAndLock(ALICE, depositAmountAlice, 0);
        (uint256 alicePoolShares,,,) = liquidityPool.userPoolInfo(0, ALICE);

        vm.warp(2 hours);
        vm.prank(ALICE);
        liquidityPool.unlockShares(0, alicePoolShares);

        vm.warp(3 hours);
        _depositAndLock(ALICE, depositAmountAlice, 0);
        (alicePoolShares,,,) = liquidityPool.userPoolInfo(0, ALICE);

        vm.warp(5 hours);
        vm.prank(ALICE);
        liquidityPool.unlockShares(0, alicePoolShares);

        // ASSERT
        (uint256 poolShares, uint256 unlockedPoolShares, uint128 nextIndex,) = liquidityPool.userPoolInfo(0, ALICE);
        assertEq(poolShares, 0);
        assertEq(unlockedPoolShares, 0);
        assertEq(nextIndex, 2);
    }

    function testRequestLoss() public {
        // ARRANGE
        deal(address(collateral), address(liquidityPool), 100_000 ether, true);
        uint256 balanceBefore = collateral.balanceOf(address(mockLiquidityPoolAdapter));

        // ACT
        vm.prank(address(mockLiquidityPoolAdapter));
        liquidityPool.requestLossPayout(100 ether);

        // ASSERT
        uint256 balanceAfter = collateral.balanceOf(address(mockLiquidityPoolAdapter));
        assertEq(balanceAfter - balanceBefore, 100 ether);
    }

    function testOnlyValidLPACanRequestLoss() public {
        // ARRANGE
        deal(address(collateral), address(liquidityPool), 100_000 ether, true);
        vm.mockCall(
            address(mockController),
            abi.encodeWithSelector(IController.isLiquidityPoolAdapter.selector),
            abi.encode(false)
        );

        // ACT
        vm.expectRevert("LiquidityPool::_onlyValidLiquidityPoolAdapter: Caller not a valid liquidity pool adapter");
        vm.prank(address(mockLiquidityPoolAdapter));
        liquidityPool.requestLossPayout(100 ether);
    }

    function testRequestLossNoLiquidity() public {
        // ACT
        vm.expectRevert("LiquidityPool::requestLossPayout: Payout exceeds limit");
        vm.prank(address(mockLiquidityPoolAdapter));
        liquidityPool.requestLossPayout(100 ether);
    }

    function testDepositFeesWhenNoShares() public {
        // ACT
        vm.prank(address(mockLiquidityPoolAdapter));
        collateral.approve(address(liquidityPool), 100 ether);
        vm.prank(address(mockLiquidityPoolAdapter));
        liquidityPool.depositFees(100 ether);

        // ASSERT
        assertEq(collateral.balanceOf(address(liquidityPool)), 100 ether);
        assertEq(liquidityPool.totalSupply(), 0);
    }

    function testDepositFeesWhenNoLock() public {
        // ARRANGE
        uint256 depositAmountAlice = 10 * 1e8;
        uint256 feeAmount = 22 * 1e8;
        uint256 sharesAlice = _deposit(ALICE, depositAmountAlice);

        // ACT
        vm.prank(address(mockLiquidityPoolAdapter));
        collateral.approve(address(liquidityPool), feeAmount);
        vm.prank(address(mockLiquidityPoolAdapter));
        liquidityPool.depositFees(feeAmount);

        // ASSERT
        assertEq(collateral.balanceOf(address(liquidityPool)), depositAmountAlice + feeAmount);
        assertEq(liquidityPool.totalSupply(), sharesAlice);
    }

    function testDepositFeesMultiplePools() public {
        // ARRANGE
        uint16 multiplier = uint16(FULL_PERCENT);
        _addPool(0, multiplier);
        uint16 multiplier2 = 2 * uint16(FULL_PERCENT);
        _addPool(0, multiplier2);

        uint256 depositAmountAlice = 10 * 1e8;
        _depositAndLock(ALICE, depositAmountAlice, 0);

        uint256 depositAmountBob = depositAmountAlice;
        _depositAndLock(BOB, depositAmountBob, 1);

        uint256 depositFeesAmount = 30 * 1e8;
        _depositFees(depositFeesAmount);

        uint256 aliceBalanceBefore = collateral.balanceOf(ALICE);
        uint256 bobBalanceBefore = collateral.balanceOf(BOB);

        // ACT
        _withdrawFromPool(ALICE, 0, type(uint256).max);
        _withdrawFromPool(BOB, 1, type(uint256).max);

        // ASSERT
        uint256 aliceBalanceAfter = collateral.balanceOf(ALICE);
        uint256 bobBalanceAfter = collateral.balanceOf(BOB);

        assertEq(aliceBalanceAfter - aliceBalanceBefore, depositAmountAlice + (depositFeesAmount * 2 / 5));
        assertEq(bobBalanceAfter - bobBalanceBefore, depositAmountBob + (depositFeesAmount * 3 / 5));
    }

    function testDepositFeesMultiplePools_OneWithoutMultiplier() public {
        // ARRANGE
        uint16 multiplier = uint16(FULL_PERCENT);
        _addPool(0, multiplier);
        uint16 multiplier2 = 0;
        _addPool(0, multiplier2);

        uint256 depositAmountAlice = 10 * 1e8;
        _depositAndLock(ALICE, depositAmountAlice, 0);

        uint256 depositAmountBob = depositAmountAlice;
        _depositAndLock(BOB, depositAmountBob, 1);

        uint256 depositFeesAmount = 30 * 1e8;
        _depositFees(depositFeesAmount);

        uint256 aliceBalanceBefore = collateral.balanceOf(ALICE);
        uint256 bobBalanceBefore = collateral.balanceOf(BOB);

        // ACT
        _withdrawFromPool(ALICE, 0, type(uint256).max);
        _withdrawFromPool(BOB, 1, type(uint256).max);

        // ASSERT
        uint256 aliceBalanceAfter = collateral.balanceOf(ALICE);
        uint256 bobBalanceAfter = collateral.balanceOf(BOB);

        assertEq(aliceBalanceAfter - aliceBalanceBefore, depositAmountAlice + (depositFeesAmount * 2 / 3));
        assertEq(bobBalanceAfter - bobBalanceBefore, depositAmountBob + (depositFeesAmount / 3));
    }

    function testDefaultLockTime() public {
        // ARRANGE
        uint256 defaultlockTime = 1 hours;
        ILiquidityPool liquidityPoolImplementation = new LiquidityPool(
            mockUnlimitedOwner,
            collateral,
            mockController
        );

        liquidityPool = LiquidityPool(
            address(new TransparentUpgradeableProxy(address(liquidityPoolImplementation), address(1), ""))
        );

        vm.prank(UNLIMITED_OWNER);
        liquidityPool.initialize("Test LP", "TLPS", defaultlockTime, 0, 0, 0);

        vm.warp(0);
        uint256 depositAmountAlice = 10 * 1e8;
        uint256 sharesAlice = _deposit(ALICE, depositAmountAlice);

        // ACT
        vm.expectRevert("LiquidityPool::_canWithdrawLps: User cannot withdraw LP tokens");
        vm.prank(ALICE);
        liquidityPool.withdraw(sharesAlice, 0);

        // ASSERT
        vm.warp(2 hours);
        vm.prank(ALICE);
        liquidityPool.withdraw(sharesAlice, 0);
    }

    function testTransferAfterDeposit() public {
        // ARRANGE
        uint256 defaultlockTime = 1 hours;
        ILiquidityPool liquidityPoolImplementation = new LiquidityPool(
            mockUnlimitedOwner,
            collateral,
            mockController
        );

        liquidityPool = LiquidityPool(
            address(new TransparentUpgradeableProxy(address(liquidityPoolImplementation), address(1), ""))
        );

        vm.prank(UNLIMITED_OWNER);
        liquidityPool.initialize("Test LP", "TLPS", defaultlockTime, 0, 0, 0);

        vm.warp(0);
        uint256 depositAmountAlice = 10 * 1e8;
        uint256 sharesAlice = _deposit(ALICE, depositAmountAlice);

        // ACT
        vm.expectRevert("LiquidityPool::_canTransfer: User cannot transfer LP tokens");
        vm.prank(ALICE);
        liquidityPool.transfer(BOB, sharesAlice);

        // ASSERT
        vm.warp(2 hours);
        vm.prank(ALICE);
        liquidityPool.transfer(BOB, sharesAlice);
    }

    function testDepositSlippage() public {
        // ARRANGE
        uint256 depositAmountAlice = 10 * 1e8;
        uint256 expectedShares = liquidityPool.previewDeposit(depositAmountAlice);

        // ACT & ASSERT
        vm.expectRevert("LiquidityPool::_depositAsset: Bad slippage");
        vm.prank(ALICE);
        liquidityPool.deposit(depositAmountAlice, expectedShares + 1);
    }

    function testVerifyPoolId() public {
        // ACT
        vm.expectRevert("LiquidityPool::_verifyPoolId: Invalid pool id");
        vm.prank(ALICE);
        liquidityPool.depositAndLock(100 ether, 0, 0);
    }

    function testWithdrawSlippage() public {
        // ARRANGE
        uint256 depositAmountAlice = 10 * 1e8;
        uint256 sharesAlice = _deposit(ALICE, depositAmountAlice);

        // ACT & ASSERT
        vm.expectRevert("LiquidityPool::_withdrawShares: Bad slippage");
        vm.prank(ALICE);
        liquidityPool.withdraw(sharesAlice, depositAmountAlice + 1);
    }

    function testVerifyPoolParameters() public {
        vm.expectRevert("LiquidityPool::_verifyPoolParameters: Invalid pool lockTime");
        _addPool(365 days + 1, 0);
        vm.expectRevert("LiquidityPool::_verifyPoolParameters: Invalid pool multiplier");
        _addPool(0, 5 * uint16(FULL_PERCENT) + 1);
    }

    function testViewFunctions() public {
        // ARRANGE
        uint256 depositAmountAlice = 10 * 1e8;
        uint256 sharesAlice = _deposit(ALICE, depositAmountAlice);

        // ASSERT
        assertEq(liquidityPool.asset(), address(collateral));
        assertEq(liquidityPool.convertToAssets(sharesAlice), depositAmountAlice);
        assertEq(liquidityPool.previewMint(sharesAlice), depositAmountAlice);
        assertEq(liquidityPool.previewWithdraw(depositAmountAlice), sharesAlice);
        assertEq(liquidityPool.convertToShares(depositAmountAlice), sharesAlice);
    }

    function testUserWithdrawalFee() public {
        // ARRANGE
        ILiquidityPool liquidityPoolImplementation = new LiquidityPool(
            mockUnlimitedOwner,
            collateral,
            mockController
        );

        liquidityPool = LiquidityPool(
            address(new TransparentUpgradeableProxy(address(liquidityPoolImplementation), address(1), ""))
        );

        vm.prank(UNLIMITED_OWNER);
        liquidityPool.initialize("Test LP", "TLPS", 6 hours, FULL_PERCENT / 10, 3 days, 0);

        vm.warp(4 days);
        uint256 depositAmountAlice = 10 * 1e8;
        uint256 sharesAlice = _deposit(ALICE, depositAmountAlice);

        // ACT
        vm.warp(5 days);
        uint256 aliceBalanceBefore = collateral.balanceOf(ALICE);
        _withdraw(ALICE, sharesAlice);
        uint256 aliceBalanceAfter = collateral.balanceOf(ALICE);

        // ASSERT
        assertEq(aliceBalanceAfter - aliceBalanceBefore, depositAmountAlice * 9 / 10);
    }

    function testUserWithdrawalFeeWithLocking() public {
        ILiquidityPool liquidityPoolImplementation = new LiquidityPool(
            mockUnlimitedOwner,
            collateral,
            mockController
        );

        liquidityPool = LiquidityPool(
            address(new TransparentUpgradeableProxy(address(liquidityPoolImplementation), address(1), ""))
        );

        vm.prank(UNLIMITED_OWNER);
        liquidityPool.initialize("Test LP", "TLPS", 6 hours, FULL_PERCENT / 10, 3 days, 0);

        _addPool(0.5 days, 0);

        vm.warp(4 days);
        uint256 depositAmountAlice = 10 * 1e8;
        _depositAndLock(ALICE, depositAmountAlice, 0);

        // ACT
        vm.warp(5 days);
        uint256 aliceBalanceBefore = collateral.balanceOf(ALICE);
        _withdrawFromPool(ALICE, 0, type(uint256).max);
        uint256 aliceBalanceAfter = collateral.balanceOf(ALICE);

        // ASSERT
        assertEq(aliceBalanceAfter - aliceBalanceBefore, depositAmountAlice * 9 / 10);
    }

    function testEarlyWithdrawalMultipleTimes() public {
        ILiquidityPool liquidityPoolImplementation = new LiquidityPool(
            mockUnlimitedOwner,
            collateral,
            mockController
        );

        liquidityPool = LiquidityPool(
            address(new TransparentUpgradeableProxy(address(liquidityPoolImplementation), address(1), ""))
        );

        vm.prank(UNLIMITED_OWNER);
        liquidityPool.initialize("Test LP", "TLPS", 6 hours, FULL_PERCENT / 10, 3 days, 0);

        _addPool(0.5 days, 0);

        vm.warp(0);
        uint256 depositAmountAlice = 10 * 1e8;
        _depositAndLock(ALICE, depositAmountAlice, 0);

        // ACT
        vm.warp(3 days);
        _depositAndLock(BOB, depositAmountAlice, 0);

        // ASSERT
        vm.warp(4 days);
        uint256 aliceBalanceBefore = collateral.balanceOf(ALICE);
        _withdrawFromPool(ALICE, 0, type(uint256).max);
        uint256 aliceBalanceAfter = collateral.balanceOf(ALICE);

        uint256 bobBalanceBefore = collateral.balanceOf(BOB);
        _withdrawFromPool(BOB, 0, type(uint256).max);
        uint256 bobBalanceAfter = collateral.balanceOf(BOB);

        // ASSERT
        assertEq(aliceBalanceAfter - aliceBalanceBefore, depositAmountAlice);
        assertEq(bobBalanceAfter - bobBalanceBefore, depositAmountAlice * 9 / 10);
    }

    function testUpdateDefaultLockTime() public {
        // ACT
        vm.prank(UNLIMITED_OWNER);
        liquidityPool.updateDefaultLockTime(1 days);

        // ASSERT
        assertEq(liquidityPool.defaultLockTime(), 1 days);
    }

    function testUpdateEarlyWithdrawalFee() public {
        // ACT
        vm.prank(UNLIMITED_OWNER);
        liquidityPool.updateEarlyWithdrawalFee(FULL_PERCENT / 10);

        // ASSERT
        assertEq(liquidityPool.earlyWithdrawalFee(), FULL_PERCENT / 10);
    }

    function testUpdateEarlyWithdrawalTime() public {
        // ACT
        vm.prank(UNLIMITED_OWNER);
        liquidityPool.updateEarlyWithdrawalTime(1 days);

        // ASSERT
        assertEq(liquidityPool.earlyWithdrawalTime(), 1 days);
    }

    function testUpdateMinimumAmount() public {
        // ACT
        vm.prank(UNLIMITED_OWNER);
        liquidityPool.updateMinimumAmount(123);

        // ASSERT
        assertEq(liquidityPool.minimumAmount(), 123);
    }

    function testUserPoolDetailsBeforeUnlock() public {
        // ARRANGE
        uint16 multiplier = uint16(FULL_PERCENT);
        _addPool(1 hours, multiplier);

        uint256 depositAmount = 10 * 1e8;

        // Act
        uint256 shares = _depositAndLock(ALICE, depositAmount, 0);
        (uint256 poolShares,,,) = liquidityPool.userPoolInfo(0, ALICE);

        // ASSERT
        UserPoolDetails[] memory pools = liquidityPool.previewPoolsOf(ALICE);
        assertEq(pools.length, 1);
        assertEq(pools[0].poolId, 0);
        assertEq(pools[0].totalPoolShares, poolShares);
        assertEq(pools[0].unlockedPoolShares, 0);
        assertEq(pools[0].totalShares, shares);
        assertEq(pools[0].unlockedShares, 0);
        assertEq(pools[0].totalAssets, depositAmount);
        assertEq(pools[0].unlockedAssets, 0);
    }

    function testUserPoolDetailsAfterUnlock() public {
        // ARRANGE
        uint16 multiplier = uint16(FULL_PERCENT);
        _addPool(1 hours, multiplier);

        uint256 depositAmount = 10 * 1e8;

        // Act
        uint256 shares = _depositAndLock(ALICE, depositAmount, 0);
        (uint256 poolShares,,,) = liquidityPool.userPoolInfo(0, ALICE);
        vm.warp(2 hours);

        // ASSERT
        UserPoolDetails[] memory pools = liquidityPool.previewPoolsOf(ALICE);
        assertEq(pools[0].totalPoolShares, poolShares);
        assertEq(pools[0].unlockedPoolShares, poolShares);
        assertEq(pools[0].totalShares, shares);
        assertEq(pools[0].unlockedShares, shares);
        assertEq(pools[0].totalAssets, depositAmount);
        assertEq(pools[0].unlockedAssets, depositAmount);
    }

    function testPreviewPoolsharesToShares() public {
        // ARRANGE
        uint16 multiplier = uint16(FULL_PERCENT);
        _addPool(1 hours, multiplier);

        uint256 depositAmount = 10 * 1e8;

        // Act
        _depositAndLock(ALICE, depositAmount, 0);
        (uint256 poolShares,,,) = liquidityPool.userPoolInfo(0, ALICE);
        vm.warp(2 hours);

        // ASSERT
        UserPoolDetails[] memory pools = liquidityPool.previewPoolsOf(ALICE);
        assertEq(pools[0].totalPoolShares, poolShares);
        assertEq(pools[0].totalAssets, depositAmount);
        assertEq(liquidityPool.previewRedeemPoolShares(poolShares, 0), depositAmount);
    }

    function testUserPoolDetailsMultipleLocks() public {
        // ARRANGE
        uint16 multiplier = uint16(FULL_PERCENT);
        _addPool(3 hours, multiplier);

        uint256 depositAmount = 10 * 1e8;

        // Act
        uint256 shares1 = _depositAndLock(ALICE, depositAmount, 0);
        vm.warp(2 hours);
        uint256 shares2 = _depositAndLock(ALICE, depositAmount, 0);
        (uint256 poolShares,,,) = liquidityPool.userPoolInfo(0, ALICE);

        vm.warp(4 hours);

        // ASSERT
        UserPoolDetails[] memory pools = liquidityPool.previewPoolsOf(ALICE);
        assertEq(pools[0].totalPoolShares, poolShares, "totalPoolShares");
        assertEq(pools[0].unlockedPoolShares, poolShares / 2, "unlockedPoolShares");
        assertEq(pools[0].totalShares, shares1 + shares2, "totalShares");
        assertEq(pools[0].unlockedShares, shares1, "unlockedShares");
        assertEq(pools[0].totalAssets, depositAmount * 2, "totalAssets");
        assertEq(pools[0].unlockedAssets, depositAmount, "unlockedAssets");
    }

    function test_AssetDecimalsCanNotExtend18() public {
        uint8 decimals = 19;
        collateral.setDecimals(decimals);

        vm.expectRevert("LiquidityPoolVault::constructor: asset decimals must be <= 18");
        liquidityPool = new LiquidityPool(
            mockUnlimitedOwner,
            collateral,
            mockController
        );
    }

    // =============================================================
    //                            HELPER
    // =============================================================

    function _addPool(uint40 lockTime_, uint16 multiplier_) private prank(UNLIMITED_OWNER) {
        liquidityPool.addPool(lockTime_, multiplier_);
    }

    function _updatePool(uint256 poolId, uint40 lockTime_, uint16 multiplier_) private prank(UNLIMITED_OWNER) {
        liquidityPool.updatePool(poolId, lockTime_, multiplier_);
    }

    function _deposit(address user, uint256 amount) private prank(user) returns (uint256 shares) {
        collateral.approve(address(liquidityPool), amount);

        shares = liquidityPool.deposit(amount, 0);
    }

    function _lockShares(address user, uint256 shares, uint256 poolId) private prank(user) {
        liquidityPool.lockShares(shares, poolId);
    }

    function _depositAndLock(address user, uint256 amount, uint256 poolId)
        private
        prank(user)
        returns (uint256 shares)
    {
        collateral.approve(address(liquidityPool), amount);

        shares = liquidityPool.depositAndLock(amount, 0, poolId);
    }

    function _withdraw(address user, uint256 shares) private prank(user) returns (uint256 amount) {
        amount = liquidityPool.withdraw(shares, 0);
    }

    function _withdrawFromPool(address user, uint256 poolId, uint256 poolShares)
        private
        prank(user)
        returns (uint256 amount)
    {
        amount = liquidityPool.withdrawFromPool(poolId, poolShares, 0);
    }

    function _depositProfit(uint256 amount) private prank(address(mockLiquidityPoolAdapter)) {
        collateral.approve(address(liquidityPool), amount);
        liquidityPool.depositProfit(amount);
    }

    function _depositFees(uint256 amount) private prank(address(mockLiquidityPoolAdapter)) {
        collateral.approve(address(liquidityPool), amount);
        liquidityPool.depositFees(amount);
    }

    modifier prank(address executor) {
        vm.startPrank(executor);
        _;
        vm.stopPrank();
    }
}
