# FeeManager
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/fee-manager/FeeManager.sol)

**Inherits:**
[IFeeManager](/src/interfaces/IFeeManager.sol/contract.IFeeManager.md), [UnlimitedOwnable](/src/shared/UnlimitedOwnable.sol/contract.UnlimitedOwnable.md), Initializable


## State Variables
### MAX_FEE_SIZE
Maximum fee size that can be set is 50%.


```solidity
uint256 private constant MAX_FEE_SIZE = 50_00;
```


### STAKERS_FEE_SIZE
Stakers fee size


```solidity
uint256 public constant STAKERS_FEE_SIZE = 18_00;
```


### DEV_FEE_SIZE
Dev fee size


```solidity
uint256 public constant DEV_FEE_SIZE = 12_00;
```


### INSURANCE_FUND_FEE_SIZE
Insurance fund fee size


```solidity
uint256 public constant INSURANCE_FUND_FEE_SIZE = 10_00;
```


### controller
Controller contract.


```solidity
IController public immutable controller;
```


### userManager
manages fees per user.


```solidity
IUserManager public immutable userManager;
```


### referralFee
Referral fee size.

*Denominated in BPS*


```solidity
uint256 public referralFee;
```


### stakersFeeAddress
Address to collect the stakers fees to.


```solidity
address public stakersFeeAddress;
```


### devFeeAddress
Address to collect the dev fees to.


```solidity
address public devFeeAddress;
```


### insuranceFundFeeAddress
Address to collect the insurance fund fees to.


```solidity
address public insuranceFundFeeAddress;
```


### whitelabelFees
Stores what fee size of the stakers fee does a whitelabel get


```solidity
mapping(address => uint256) public whitelabelFees;
```


### customReferralFee
Stores custom referral fee for users


```solidity
mapping(address => uint256) public customReferralFee;
```


## Functions
### constructor

Constructs the FeeManager contract.


```solidity
constructor(IUnlimitedOwner unlimitedOwner_, IController controller_, IUserManager userManager_)
    UnlimitedOwnable(unlimitedOwner_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`unlimitedOwner_`|`IUnlimitedOwner`|The global owner of Unlimited Protocol.|
|`controller_`|`IController`|Controller contract.|
|`userManager_`|`IUserManager`|User manager contract.|


### initialize

Initializes the FeeManager contract.


```solidity
function initialize(
    uint256 referralFee_,
    address stakersFeeAddress_,
    address devFeeAddress_,
    address insuranceFundFeeAddress_
) external onlyOwner initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`referralFee_`|`uint256`|Referral fee size.|
|`stakersFeeAddress_`|`address`|Address to collect the stakers fees to.|
|`devFeeAddress_`|`address`|Address to collect the dev fees to.|
|`insuranceFundFeeAddress_`|`address`|Address to collect the insurance fund fees to.|


### updateReferralFee

Update referral fee.


```solidity
function updateReferralFee(uint256 referralFee_) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`referralFee_`|`uint256`|Referral fee size in BPS.|


### _updateReferralFee

Update referral fee.


```solidity
function _updateReferralFee(uint256 referralFee_) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`referralFee_`|`uint256`|Fee size in BPS.|


### updateStakersFeeAddress

Update stakers fee address.


```solidity
function updateStakersFeeAddress(address stakersFeeAddress_) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`stakersFeeAddress_`|`address`|Stakers fee address.|


### _updateStakersFeeAddress

Update stakers fee address.


```solidity
function _updateStakersFeeAddress(address stakersFeeAddress_) private nonZeroAddress(stakersFeeAddress_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`stakersFeeAddress_`|`address`|Stakers fee address.|


### updateDevFeeAddress

Update dev fee address.


```solidity
function updateDevFeeAddress(address devFeeAddress_) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`devFeeAddress_`|`address`|Dev fee address.|


### _updateDevFeeAddress

Update dev fee address.


```solidity
function _updateDevFeeAddress(address devFeeAddress_) private nonZeroAddress(devFeeAddress_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`devFeeAddress_`|`address`|Dev fee address.|


### updateInsuranceFundFeeAddress

Update insurance fund fee address.


```solidity
function updateInsuranceFundFeeAddress(address insuranceFundFeeAddress_) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`insuranceFundFeeAddress_`|`address`|Insurance fund fee address.|


### _updateInsuranceFundFeeAddress

Update insurance fund fee address.


```solidity
function _updateInsuranceFundFeeAddress(address insuranceFundFeeAddress_)
    private
    nonZeroAddress(insuranceFundFeeAddress_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`insuranceFundFeeAddress_`|`address`|Insurance fund fee address.|


### setWhitelabelFees

Update insurance fund fee address.


```solidity
function setWhitelabelFees(address whitelabelAddress_, uint256 feeSize_) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`whitelabelAddress_`|`address`|Whitelabel address.|
|`feeSize_`|`uint256`|Whitelabel fee size.|


### setCustomReferralFee

Set custom referral fee for address.


```solidity
function setCustomReferralFee(address referrer_, uint256 feeSize_) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`referrer_`|`address`|Referrer address.|
|`feeSize_`|`uint256`|Whitelabel fee size.|


### _checkFeeSize

*Checks if fee size is in bounds.*


```solidity
function _checkFeeSize(uint256 feeSize_) private pure;
```

### calculateUserOpenFeeAmount

Calculates the fee for a given user and amount.


```solidity
function calculateUserOpenFeeAmount(address user_, uint256 amount_) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user_`|`address`|User address.|
|`amount_`|`uint256`|Amount to calculate fee for.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|fee_ Fee amount.|


### calculateUserOpenFeeAmount

Calculates the fee amount for a given amount and the leverage.

*The fee is calculated in such a way, that it can be deducted from amount_ to get the margin for a position.
The margin times the leverage will be of such a volume, that the feeAmount_ is exactly the fee given by the user fee.
This function allows for the user to choose the margin, while still paying exactly the correct feeAmount.*


```solidity
function calculateUserOpenFeeAmount(address user_, uint256 amount_, uint256 leverage_)
    external
    view
    returns (uint256 feeAmount_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user_`|`address`|User address.|
|`amount_`|`uint256`|Amount to calculate the fee for.|
|`leverage_`|`uint256`|Leverage to calculate the fee for.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`feeAmount_`|`uint256`|Fee amount.|


### calculateUserExtendToLeverageFeeAmount

Calculates the fee amount for the increaseToLeverage function.

*The fee is calculated in such a way, that it can be deducted from margin_ to get the margin for a position.
The new margin times the targetLeverage will be of such a volume, that the feeAmount_ is exactly the fee given by the added volume.
This function allows for the user to choose the leverage, while still paying exactly the correct feeAmount.*


```solidity
function calculateUserExtendToLeverageFeeAmount(
    address user_,
    uint256 margin_,
    uint256 volume_,
    uint256 targetLeverage_
) external view returns (uint256 feeAmount_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user_`|`address`|User address.|
|`margin_`|`uint256`|Current margin.|
|`volume_`|`uint256`|Current volume.|
|`targetLeverage_`|`uint256`|Leverage to calculate the fee for.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`feeAmount_`|`uint256`|Fee amount.|


### calculateUserCloseFeeAmount

*Calculates the fee for a given user and close operation.*


```solidity
function calculateUserCloseFeeAmount(address user_, uint256 amount_) external view returns (uint256);
```

### _calculateUserFeeAmount

This function returns the absolute value of a fee given a user and an amount.

*Calculates the user fee for a certain amount. Mainly used to open, close and alter positions.*


```solidity
function _calculateUserFeeAmount(address user_, uint256 amount_) private view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user_`|`address`|address of the user.|
|`amount_`|`uint256`|amount of the trade.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|amount the amount to calculates the fees from.|


### depositOpenFees

Deposits open fees.


```solidity
function depositOpenFees(address user_, address asset_, uint256 amount_, address whitelabelAddress_)
    external
    onlyValidTradePair;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user_`|`address`|User that deposits the fees.|
|`asset_`|`address`|Asset to deposit the fees in.|
|`amount_`|`uint256`|Amount to deposit.|
|`whitelabelAddress_`|`address`|Whitelabel address or address(0) if not whitelabeled.|


### depositCloseFees

Deposits close fees.


```solidity
function depositCloseFees(address user_, address asset_, uint256 amount_, address whitelabelAddress_)
    external
    onlyValidTradePair;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user_`|`address`|User that deposits the fees.|
|`asset_`|`address`|Asset to deposit the fees in.|
|`amount_`|`uint256`|Amount to deposit.|
|`whitelabelAddress_`|`address`|Whitelabel address or address(0) if not whitelabeled.|


### _spreadFees

*Distributes fee to the different recievers.*


```solidity
function _spreadFees(address tradePair_, address user_, IERC20 asset_, uint256 amount_, address whitelabelAddress_)
    private;
```

### depositBorrowFees

Deposits borrow fees from TradePair.


```solidity
function depositBorrowFees(address asset_, uint256 amount_) external onlyValidTradePair;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset_`|`address`|Asset to deposit the fees in.|
|`amount_`|`uint256`|Amount to deposit.|


### _depositFeesToLiquidityPools

*Deposits fees to the liquidity pools.*


```solidity
function _depositFeesToLiquidityPools(address tradePair_, IERC20 asset_, uint256 amount_) private;
```

### _getLiquidityPoolAdapterFromTradePair

*Returns the liquidity pool adapter from a trade pair.*


```solidity
function _getLiquidityPoolAdapterFromTradePair(address tradePair_) private view returns (ILiquidityPoolAdapter);
```

### _onlyValidTradePair

*Reverts if TradePair is not valid.*


```solidity
function _onlyValidTradePair() private view;
```

### _nonZeroAddress

*Reverts if address is zero address*


```solidity
function _nonZeroAddress(address address_) private pure;
```

### onlyValidTradePair


```solidity
modifier onlyValidTradePair();
```

### nonZeroAddress


```solidity
modifier nonZeroAddress(address address_);
```

