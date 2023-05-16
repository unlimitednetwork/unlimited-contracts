// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "test/setup/WithMocks.t.sol";
import "src/fee-manager/FeeManager.sol";

contract FeeManagerTest is WithMocks {
    address private constant WHITELABEL_ADDRESS = address(9);
    address private constant STAKERS_ADDRESS = address(10);
    address private constant DEV_ADDRESS = address(11);
    address private constant INSURANCE_ADDRESS = address(12);

    ILiquidityPoolAdapter private liquidityPoolAdapter = ILiquidityPoolAdapter(address(13));

    uint256 private constant REFERRAL_FEE = 10_00;

    FeeManager feeManager;

    function setUp() public {
        IFeeManager feeManagerImplementation = new FeeManager(
            mockUnlimitedOwner,
            mockController,
            mockUserManager
        );
        feeManager = FeeManager(
            address(new TransparentUpgradeableProxy(address(feeManagerImplementation), address(mockUnlimitedOwner), ""))
        );

        vm.prank(UNLIMITED_OWNER);
        feeManager.initialize(REFERRAL_FEE, STAKERS_ADDRESS, DEV_ADDRESS, INSURANCE_ADDRESS);

        dealTokens(address(mockTradePair), 1000000 ether);

        mockTradePair.setLiquidityPoolAdapter(mockLiquidityPoolAdapter);
    }

    function testInitializable() public {
        // ARRANGE
        IFeeManager feeManagerImplementation = new FeeManager(
            mockUnlimitedOwner,
            mockController,
            mockUserManager
        );
        feeManager = FeeManager(
            address(new TransparentUpgradeableProxy(address(feeManagerImplementation), address(mockUnlimitedOwner), ""))
        );

        // ACT
        vm.prank(UNLIMITED_OWNER);
        feeManager.initialize(REFERRAL_FEE, STAKERS_ADDRESS, DEV_ADDRESS, INSURANCE_ADDRESS);

        // ASSERT
        assertEq(feeManager.referralFee(), REFERRAL_FEE);
        assertEq(feeManager.stakersFeeAddress(), STAKERS_ADDRESS);
        assertEq(feeManager.devFeeAddress(), DEV_ADDRESS);
        assertEq(feeManager.insuranceFundFeeAddress(), INSURANCE_ADDRESS);
    }

    function testDepositOpenFee() public {
        // ARRANGE
        uint256 feeAmount = 1000 ether;
        vm.startPrank(address(mockTradePair));
        collateral.approve(address(feeManager), feeAmount);

        // ACT
        feeManager.depositOpenFees(ALICE, address(collateral), feeAmount, address(0));

        // ASSERT
        uint256 stakersAmount = feeAmount * feeManager.STAKERS_FEE_SIZE() / FULL_PERCENT;
        uint256 stakersBalance = collateral.balanceOf(STAKERS_ADDRESS);
        assertEq(stakersBalance, stakersAmount);

        uint256 devAmount = feeAmount * feeManager.DEV_FEE_SIZE() / FULL_PERCENT;
        uint256 devBalance = collateral.balanceOf(DEV_ADDRESS);
        assertEq(devBalance, devAmount);

        uint256 insuranceAmount = feeAmount * feeManager.INSURANCE_FUND_FEE_SIZE() / FULL_PERCENT;
        uint256 insuranceBalance = collateral.balanceOf(INSURANCE_ADDRESS);
        assertEq(insuranceBalance, insuranceAmount);

        uint256 amountLeft = feeAmount - stakersAmount - devAmount - insuranceAmount;
        uint256 liquidityAdapterbalance = collateral.balanceOf(address(mockLiquidityPoolAdapter));
        assertEq(liquidityAdapterbalance, amountLeft);
    }

    function testDepositCloseFee() public {
        // ARRANGE
        uint256 feeAmount = 1000 ether;
        vm.startPrank(address(mockTradePair));
        collateral.approve(address(feeManager), feeAmount);

        // ACT
        feeManager.depositCloseFees(ALICE, address(collateral), feeAmount, address(0));

        // ASSERT
        uint256 stakersAmount = feeAmount * feeManager.STAKERS_FEE_SIZE() / FULL_PERCENT;
        uint256 stakersBalance = collateral.balanceOf(STAKERS_ADDRESS);
        assertEq(stakersBalance, stakersAmount);

        uint256 devAmount = feeAmount * feeManager.DEV_FEE_SIZE() / FULL_PERCENT;
        uint256 devBalance = collateral.balanceOf(DEV_ADDRESS);
        assertEq(devBalance, devAmount);

        uint256 insuranceAmount = feeAmount * feeManager.INSURANCE_FUND_FEE_SIZE() / FULL_PERCENT;
        uint256 insuranceBalance = collateral.balanceOf(INSURANCE_ADDRESS);
        assertEq(insuranceBalance, insuranceAmount);

        uint256 amountLeft = feeAmount - stakersAmount - devAmount - insuranceAmount;
        uint256 liquidityAdapterbalance = collateral.balanceOf(address(mockLiquidityPoolAdapter));
        assertEq(liquidityAdapterbalance, amountLeft);
    }

    function testDepositOpenFee_withReferrer() public {
        // ARRANGE
        mockUserManager.setUserReferrer(ALICE, BOB);

        uint256 feeAmount = 1000 ether;
        vm.startPrank(address(mockTradePair));
        collateral.approve(address(feeManager), feeAmount);

        // ACT
        feeManager.depositOpenFees(ALICE, address(collateral), feeAmount, address(0));

        // ASSERT
        uint256 referrerAmount = feeAmount * REFERRAL_FEE / FULL_PERCENT;
        uint256 referrerBalance = collateral.balanceOf(BOB);
        assertEq(referrerBalance, referrerAmount);

        feeAmount -= referrerAmount;

        uint256 stakersAmount = feeAmount * feeManager.STAKERS_FEE_SIZE() / FULL_PERCENT;
        uint256 stakersBalance = collateral.balanceOf(STAKERS_ADDRESS);
        assertEq(stakersBalance, stakersAmount);

        uint256 devAmount = feeAmount * feeManager.DEV_FEE_SIZE() / FULL_PERCENT;
        uint256 devBalance = collateral.balanceOf(DEV_ADDRESS);
        assertEq(devBalance, devAmount);

        uint256 insuranceAmount = feeAmount * feeManager.INSURANCE_FUND_FEE_SIZE() / FULL_PERCENT;
        uint256 insuranceBalance = collateral.balanceOf(INSURANCE_ADDRESS);
        assertEq(insuranceBalance, insuranceAmount);

        uint256 amountLeft = feeAmount - stakersAmount - devAmount - insuranceAmount;
        uint256 liquidityAdapterbalance = collateral.balanceOf(address(mockLiquidityPoolAdapter));
        assertEq(liquidityAdapterbalance, amountLeft);
    }

    function testDepositOpenFee_withCustomReferral() public {
        // ARRANGE
        mockUserManager.setUserReferrer(ALICE, BOB);
        uint256 customReferralFee = 20_00;
        vm.prank(UNLIMITED_OWNER);
        feeManager.setCustomReferralFee(BOB, customReferralFee);

        uint256 feeAmount = 1000 ether;
        vm.startPrank(address(mockTradePair));
        collateral.approve(address(feeManager), feeAmount);

        // ACT
        feeManager.depositOpenFees(ALICE, address(collateral), feeAmount, address(0));

        // ASSERT
        uint256 referrerAmount = feeAmount * customReferralFee / FULL_PERCENT;
        uint256 referrerBalance = collateral.balanceOf(BOB);
        assertEq(referrerBalance, referrerAmount);

        feeAmount -= referrerAmount;

        uint256 stakersAmount = feeAmount * feeManager.STAKERS_FEE_SIZE() / FULL_PERCENT;
        uint256 stakersBalance = collateral.balanceOf(STAKERS_ADDRESS);
        assertEq(stakersBalance, stakersAmount);

        uint256 devAmount = feeAmount * feeManager.DEV_FEE_SIZE() / FULL_PERCENT;
        uint256 devBalance = collateral.balanceOf(DEV_ADDRESS);
        assertEq(devBalance, devAmount);

        uint256 insuranceAmount = feeAmount * feeManager.INSURANCE_FUND_FEE_SIZE() / FULL_PERCENT;
        uint256 insuranceBalance = collateral.balanceOf(INSURANCE_ADDRESS);
        assertEq(insuranceBalance, insuranceAmount);

        uint256 amountLeft = feeAmount - stakersAmount - devAmount - insuranceAmount;
        uint256 liquidityAdapterbalance = collateral.balanceOf(address(mockLiquidityPoolAdapter));
        assertEq(liquidityAdapterbalance, amountLeft);
    }

    function testDepositOpenFee_withWhitelabel() public {
        // ARRANGE
        address whitelabel = address(20);
        uint256 whitelabelFeeSize = 40_00;
        vm.prank(UNLIMITED_OWNER);
        feeManager.setWhitelabelFees(whitelabel, whitelabelFeeSize);

        uint256 feeAmount = 1000 ether;
        vm.startPrank(address(mockTradePair));
        collateral.approve(address(feeManager), feeAmount);

        // ACT
        feeManager.depositOpenFees(ALICE, address(collateral), feeAmount, whitelabel);

        // ASSERT

        // assert stakers and whitelabel fees collected
        uint256 stakersAmount = feeAmount * feeManager.STAKERS_FEE_SIZE() / FULL_PERCENT;

        uint256 whitelabelAmount = stakersAmount * whitelabelFeeSize / FULL_PERCENT;
        uint256 whitelabelBalance = collateral.balanceOf(whitelabel);
        assertEq(whitelabelBalance, whitelabelAmount);

        uint256 stakersBalance = collateral.balanceOf(STAKERS_ADDRESS);
        assertEq(stakersBalance, stakersAmount - whitelabelAmount);

        // assert other fees collected
        uint256 devAmount = feeAmount * feeManager.DEV_FEE_SIZE() / FULL_PERCENT;
        uint256 devBalance = collateral.balanceOf(DEV_ADDRESS);
        assertEq(devBalance, devAmount);

        uint256 insuranceAmount = feeAmount * feeManager.INSURANCE_FUND_FEE_SIZE() / FULL_PERCENT;
        uint256 insuranceBalance = collateral.balanceOf(INSURANCE_ADDRESS);
        assertEq(insuranceBalance, insuranceAmount);

        uint256 amountLeft = feeAmount - stakersAmount - devAmount - insuranceAmount;
        uint256 liquidityAdapterbalance = collateral.balanceOf(address(mockLiquidityPoolAdapter));
        assertEq(liquidityAdapterbalance, amountLeft);
    }

    function testDepositOpenFee_withUnregisteredWhitelabel() public {
        // ARRANGE
        address whitelabel = address(20);

        uint256 feeAmount = 1000 ether;
        vm.startPrank(address(mockTradePair));
        collateral.approve(address(feeManager), feeAmount);

        // ACT
        feeManager.depositOpenFees(ALICE, address(collateral), feeAmount, whitelabel);

        // ASSERT

        // assert stakers and whitelabel fees collected
        uint256 stakersAmount = feeAmount * feeManager.STAKERS_FEE_SIZE() / FULL_PERCENT;

        uint256 whitelabelAmount = 0;
        uint256 whitelabelBalance = collateral.balanceOf(whitelabel);
        assertEq(whitelabelBalance, whitelabelAmount);

        uint256 stakersBalance = collateral.balanceOf(STAKERS_ADDRESS);
        assertEq(stakersBalance, stakersAmount - whitelabelAmount);

        // assert other fees collected
        uint256 devAmount = feeAmount * feeManager.DEV_FEE_SIZE() / FULL_PERCENT;
        uint256 devBalance = collateral.balanceOf(DEV_ADDRESS);
        assertEq(devBalance, devAmount);

        uint256 insuranceAmount = feeAmount * feeManager.INSURANCE_FUND_FEE_SIZE() / FULL_PERCENT;
        uint256 insuranceBalance = collateral.balanceOf(INSURANCE_ADDRESS);
        assertEq(insuranceBalance, insuranceAmount);

        uint256 amountLeft = feeAmount - stakersAmount - devAmount - insuranceAmount;
        uint256 liquidityAdapterbalance = collateral.balanceOf(address(mockLiquidityPoolAdapter));
        assertEq(liquidityAdapterbalance, amountLeft);
    }

    function testDepositBorrowFee() public {
        // ARRANGE
        uint256 feeAmount = 1000 ether;
        vm.startPrank(address(mockTradePair));
        collateral.approve(address(feeManager), feeAmount);

        // ACT
        feeManager.depositBorrowFees(address(collateral), feeAmount);

        // ASSERT
        uint256 liquidityAdapterbalance = collateral.balanceOf(address(mockLiquidityPoolAdapter));
        assertEq(liquidityAdapterbalance, feeAmount);
    }

    function testOnlyValidTradePair() public {
        // ARRANGE
        vm.mockCall(
            address(mockController),
            abi.encodeWithSelector(MockController.isTradePair.selector, address(this)),
            abi.encode(false)
        );

        // ACT
        vm.expectRevert("FeeManager::_onlyValidTradePair: Caller is not a trade pair");
        feeManager.depositBorrowFees(address(collateral), 1 ether);
    }

    function testOnlyController() public {
        vm.expectRevert("UnlimitedOwnable::_onlyOwner: Caller is not the Unlimited owner");
        feeManager.updateReferralFee(1 ether);
    }

    function testNonZeroAddress() public {
        vm.expectRevert("FeeManager::_nonZeroAddress: Address cannot be 0");
        vm.prank(UNLIMITED_OWNER);
        feeManager.updateInsuranceFundFeeAddress(address(0));
    }

    function testSetReferralFee() public {
        // ACT
        vm.prank(UNLIMITED_OWNER);
        feeManager.updateReferralFee(100);

        // ASSERT
        assertEq(feeManager.referralFee(), 100);
    }

    function testCheckFeeSize() public {
        // ACT
        vm.expectRevert("FeeManager::_checkFeeSize: Bad fee size");
        vm.prank(UNLIMITED_OWNER);
        feeManager.updateReferralFee(50_01);
    }

    function testcalculateUserOpenFeeAmount() public {
        assertEq(feeManager.calculateUserOpenFeeAmount(ALICE, 1000 ether), 1 ether);
        mockUserManager.setUserFee(23);
        assertEq(feeManager.calculateUserOpenFeeAmount(ALICE, 1000 ether), 2.3 ether);
    }

    function testcalculateUserCloseFeeAmount() public {
        assertEq(feeManager.calculateUserCloseFeeAmount(ALICE, 1000 ether), 1 ether);
        mockUserManager.setUserFee(23);
        assertEq(feeManager.calculateUserCloseFeeAmount(ALICE, 1000 ether), 2.3 ether);
    }

    function testUpdateStakersFeeAddress() public {
        // ARRANGE
        address newAddress = address(20);

        // ACT
        vm.prank(UNLIMITED_OWNER);
        feeManager.updateStakersFeeAddress(newAddress);

        // ASSERT
        assertEq(feeManager.stakersFeeAddress(), newAddress);
    }

    function testUpdateDevFeeAddress() public {
        // ARRANGE
        address newAddress = address(20);

        // ACT
        vm.prank(UNLIMITED_OWNER);
        feeManager.updateDevFeeAddress(newAddress);

        // ASSERT
        assertEq(feeManager.devFeeAddress(), newAddress);
    }

    function testUpdateInsuranceFundFeeAddress() public {
        // ARRANGE
        address newAddress = address(20);

        // ACT
        vm.prank(UNLIMITED_OWNER);
        feeManager.updateInsuranceFundFeeAddress(newAddress);

        // ASSERT
        assertEq(feeManager.insuranceFundFeeAddress(), newAddress);
    }

    function testOpenFeeWithLeverage() public {
        // ARRANGE
        uint256 initialBalance = 1005 ether;
        uint256 leverage = 5 * LEVERAGE_MULTIPLIER;

        // ACT
        uint256 feeAmount = feeManager.calculateUserOpenFeeAmount(ALICE, initialBalance, leverage);

        // ASSERT
        assertEq(feeAmount, 5 ether);
    }

    function testOpenFeeWithLeverage2() public {
        // ARRANGE
        uint256 initialBalance = 1100 ether;
        uint256 leverage = 100 * LEVERAGE_MULTIPLIER;

        // ACT
        uint256 feeAmount = feeManager.calculateUserOpenFeeAmount(ALICE, initialBalance, leverage);

        // ASSERT
        assertEq(feeAmount, 100 ether);
    }

    function testIncreaseLeverageFee() public {
        // ARRANGE
        uint256 initialBalance = 1005 ether;
        uint256 firstLeverage = 5 * LEVERAGE_MULTIPLIER;
        uint256 finalLeverage = 10 * LEVERAGE_MULTIPLIER;

        uint256 comparativeFeeAmount = feeManager.calculateUserOpenFeeAmount(ALICE, initialBalance, finalLeverage);

        // ACT
        uint256 stepwiseFeeAmount = feeManager.calculateUserOpenFeeAmount(ALICE, initialBalance, firstLeverage);
        uint256 firstMargin = initialBalance - stepwiseFeeAmount;
        uint256 firstVolume = firstMargin * firstLeverage / LEVERAGE_MULTIPLIER;

        stepwiseFeeAmount +=
            feeManager.calculateUserExtendToLeverageFeeAmount(ALICE, firstMargin, firstVolume, finalLeverage);

        // ASSERT
        assertEq(stepwiseFeeAmount, comparativeFeeAmount);
    }
}
