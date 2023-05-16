# LiquidityPool
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/liquidity-pools/LiquidityPool.sol)

**Inherits:**
[ILiquidityPool](/src/interfaces/ILiquidityPool.sol/contract.ILiquidityPool.md), [UnlimitedOwnable](/src/shared/UnlimitedOwnable.sol/contract.UnlimitedOwnable.md), Initializable, [LiquidityPoolVault](/src/liquidity-pools/LiquidityPoolVault.sol/contract.LiquidityPoolVault.md)

LiquidityPool is a contract that allows users to deposit and withdraw liquidity.
It follows most of the EIP4625 standard. Users deposit an asset and receive liquidity pool shares (LPS).
Users can withdraw their LPS at any time.
Users can also decide to lock their LPS for a period of time to receive a multiplier on their rewards.
The lock mechanism is realized by the pools in this contract.
Each pool defines a different lock period and multiplier.


## State Variables
### MAXIMUM_MULTIPLIER

```solidity
uint256 constant MAXIMUM_MULTIPLIER = 5 * FULL_PERCENT;
```


### MAXIMUM_LOCK_TIME

```solidity
uint256 constant MAXIMUM_LOCK_TIME = 365 days;
```


### controller
Controller contract.


```solidity
IController public immutable controller;
```


### defaultLockTime
Time locked after the deposit.


```solidity
uint256 public defaultLockTime;
```


### earlyWithdrawalFee
Relative fee to early withdraw non-locked shares.


```solidity
uint256 public earlyWithdrawalFee;
```


### earlyWithdrawalTime
Time when the early withdrawal fee is applied shares.


```solidity
uint256 public earlyWithdrawalTime;
```


### minimumAmount
minimum amount of asset to stay in the pool.


```solidity
uint256 public minimumAmount;
```


### pools
Array of pools with different lock time and multipliers.


```solidity
LockPoolInfo[] public pools;
```


### lastDepositTime
Last deposit time of a user.


```solidity
mapping(address => uint256) public lastDepositTime;
```


### userPoolInfo
Mapping of UserPoolInfo for each user for each pool. userPoolInfo[poolId][user]


```solidity
mapping(uint256 => mapping(address => UserPoolInfo)) public userPoolInfo;
```


## Functions
### constructor

Initialize the contract.


```solidity
constructor(IUnlimitedOwner unlimitedOwner_, IERC20Metadata collateral_, IController controller_)
    LiquidityPoolVault(collateral_)
    UnlimitedOwnable(unlimitedOwner_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`unlimitedOwner_`|`IUnlimitedOwner`|The address of the unlimited owner.|
|`collateral_`|`IERC20Metadata`|The address of the collateral.|
|`controller_`|`IController`|The address of the controller.|


### initialize

Initialize the contract.


```solidity
function initialize(
    string memory name_,
    string memory symbol_,
    uint256 defaultLockTime_,
    uint256 earlyWithdrawalFee_,
    uint256 earlyWithdrawalTime_,
    uint256 minimumAmount_
) public onlyOwner initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`name_`|`string`|The name of the pool's ERC20 liquidity token.|
|`symbol_`|`string`|The symbol of the pool's ERC20 liquidity token.|
|`defaultLockTime_`|`uint256`|The default lock time of the pool.|
|`earlyWithdrawalFee_`|`uint256`|The early withdrawal fee of the pool.|
|`earlyWithdrawalTime_`|`uint256`|The early withdrawal time of the pool.|
|`minimumAmount_`|`uint256`|The minimum amount of the pool (subtracted from available liquidity).|


### availableLiquidity

Returns the total available liquidity in the pool.

*The available liquidity is reduced by the minimum amount to make sure no rounding errors occur when liquidity is
drained.*


```solidity
function availableLiquidity() public view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The total available liquidity in the pool.|


### previewPoolsOf

Returns information about user's pool deposits. Including locked and unlocked pool shares, shares and assets.


```solidity
function previewPoolsOf(address user_) external view returns (UserPoolDetails[] memory userPools);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`userPools`|`UserPoolDetails[]`|an array of UserPoolDetails. This informs about current user's locked and unlocked shares|


### previewPoolOf

Returns information about user's pool deposits. Including locked and unlocked pool shares, shares and assets.


```solidity
function previewPoolOf(address user_, uint256 poolId_) public view returns (UserPoolDetails memory userPool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user_`|`address`|the user to get the pool details for|
|`poolId_`|`uint256`|the id of the pool to preview|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`userPool`|`UserPoolDetails`|the UserPoolDetails. This informs about current user's locked and unlocked shares|


### canTransferLps

Function to check if a user is able to transfer their shares to another address


```solidity
function canTransferLps(address user_) public view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user_`|`address`|the address of the user|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool true if the user is able to transfer their shares|


### canWithdrawLps

Function to check if a user is able to withdraw their shares, with a possible loss to earlyWithdrawalFee


```solidity
function canWithdrawLps(address user_) public view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user_`|`address`|the address of the user|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool true if the user is able to withdraw their shares|


### userWithdrawalFee

Returns a possible earlyWithdrawalFee for a user. Fee applies when the user withdraws after the earlyWithdrawalTime and before the defaultLockTime


```solidity
function userWithdrawalFee(address user_) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user_`|`address`|the address of the user|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 the earlyWithdrawalFee or 0|


### previewRedeemPoolShares

Preview function to convert locked pool shares to asset


```solidity
function previewRedeemPoolShares(uint256 poolShares_, uint256 poolId_) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`poolShares_`|`uint256`|the amount of pool shares to convert|
|`poolId_`|`uint256`|the id of the pool to convert|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the amount of assets that would be received|


### deposit

Deposits an amount of the collateral asset.


```solidity
function deposit(uint256 assets_, uint256 minShares_) external updateUser(msg.sender) returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assets_`|`uint256`|The amount of the collateral asset to deposit.|
|`minShares_`|`uint256`|The desired minimum amount to receive in exchange for the deposited collateral. Reverts otherwise.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of shares received for the deposited collateral.|


### depositAndLock

Deposits an amount of the collateral asset and locks it directly


```solidity
function depositAndLock(uint256 assets_, uint256 minShares_, uint256 poolId_)
    external
    verifyPoolId(poolId_)
    updateUser(msg.sender)
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assets_`|`uint256`|The amount of the collateral asset to deposit.|
|`minShares_`|`uint256`|The desired minimum amount to receive in exchange for the deposited collateral. Reverts otherwise.|
|`poolId_`|`uint256`|Id of the pool to lock the deposit|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of shares received for the deposited collateral.|


### lockShares

Locks LPs for a user.


```solidity
function lockShares(uint256 shares_, uint256 poolId_) external verifyPoolId(poolId_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`shares_`|`uint256`|The amount of shares to lock.|
|`poolId_`|`uint256`|Id of the pool to lock the deposit|


### _depositAsset

*deposits assets into the pool*


```solidity
function _depositAsset(uint256 assets_, uint256 minShares_, address receiver_) private returns (uint256);
```

### _lockShares

*Internal function to lock shares*


```solidity
function _lockShares(uint256 lpShares_, uint256 poolId_, address user_) private;
```

### _addUserPoolDeposit


```solidity
function _addUserPoolDeposit(UserPoolInfo storage _userPoolInfo, uint256 newPoolShares_) private;
```

### withdraw

Withdraws an amount of the collateral asset.


```solidity
function withdraw(uint256 shares_, uint256 minOut_) external canWithdraw(msg.sender) returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`shares_`|`uint256`|The amount of shares to withdraw.|
|`minOut_`|`uint256`|The desired minimum amount of collateral to receive in exchange for the withdrawn shares. Reverts otherwise.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of collateral received for the withdrawn shares.|


### withdrawFromPool

Unlocks and withdraws an amount of the collateral asset.


```solidity
function withdrawFromPool(uint256 poolId_, uint256 poolShares_, uint256 minOut_)
    external
    canWithdraw(msg.sender)
    verifyPoolId(poolId_)
    updateUserPoolDeposits(msg.sender, poolId_)
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`poolId_`|`uint256`|the id of the pool to unlock the shares from|
|`poolShares_`|`uint256`|the amount of pool shares to unlock and withdraw|
|`minOut_`|`uint256`|the desired minimum amount of collateral to receive in exchange for the withdrawn shares. Reverts otherwise. return the amount of collateral received for the withdrawn shares.|


### unlockShares

Unlocks shares and returns them to the user.


```solidity
function unlockShares(uint256 poolId_, uint256 poolShares_)
    external
    verifyPoolId(poolId_)
    updateUserPoolDeposits(msg.sender, poolId_)
    returns (uint256 lpAmount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`poolId_`|`uint256`|the id of the pool to unlock the shares from|
|`poolShares_`|`uint256`|the amount of pool shares to unlock|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`lpAmount`|`uint256`|the amount of shares unlocked|


### _withdrawShares

*Withdraws share frm the pool*


```solidity
function _withdrawShares(address user, uint256 shares, uint256 minOut, address receiver) private returns (uint256);
```

### _unlockShares

*Internal function to unlock pool shares*


```solidity
function _unlockShares(address user_, uint256 poolId_, uint256 poolShares_) private returns (uint256 lpAmount);
```

### _poolSharesToShares

*Converts Pool Shares to Shares*


```solidity
function _poolSharesToShares(uint256 poolShares_, uint256 poolId_) internal view returns (uint256);
```

### _convertToPoolShares

*Converts an amount of shares to the equivalent amount of pool shares*


```solidity
function _convertToPoolShares(uint256 newLps_, uint256 totalPoolShares_, uint256 lockedLps_, Math.Rounding rounding_)
    private
    pure
    returns (uint256 newPoolShares);
```

### _totalUnlockedPoolShares

Previews the total amount of unlocked pool shares for a user


```solidity
function _totalUnlockedPoolShares(address user_, uint256 poolId_) internal view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user_`|`address`|the user to preview the unlocked pool shares for|
|`poolId_`|`uint256`|the id of the pool to preview|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the total amount of unlocked pool shares|


### _updateUserPoolDeposits

*Updates the user's pool deposit info. This function effectively unlockes the eligible pool shares.
It works by iterating over the user's deposits and unlocking the shares that have been locked for more than the
lock period.*


```solidity
function _updateUserPoolDeposits(address user_, uint256 poolId_) private;
```

### _previewPoolShareUnlock

Previews the amount of unlocked pool shares for a user, by iterating through the user's deposits.


```solidity
function _previewPoolShareUnlock(address user_, uint256 poolId_)
    private
    view
    returns (uint256 newUnlockedPoolShares, uint256 newNextIndex);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user_`|`address`|the user to preview the unlocked pool shares for|
|`poolId_`|`uint256`|the id of the pool to preview|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`newUnlockedPoolShares`|`uint256`|the total amount of new unlocked pool shares|
|`newNextIndex`|`uint256`|the index of the next deposit to be unlocked|


### depositProfit

deposits a protocol profit when a trader made a loss

*the allowande of the sender needs to be sufficient*


```solidity
function depositProfit(uint256 profit_) external onlyValidLiquidityPoolAdapter;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`profit_`|`uint256`|the profit of the asset with respect to the asset multiplier|


### depositFees

Deposits fees from the protocol into this liquidity pool. Distributes assets over the liquidity providers by increasing LP shares.


```solidity
function depositFees(uint256 amount_) external onlyValidLiquidityPoolAdapter;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount_`|`uint256`|the amount of fees to deposit|


### requestLossPayout

requests payout of a protocol loss when a trader made a profit

*pays out the loss when msg.sender is a registered liquidity pool adapter*


```solidity
function requestLossPayout(uint256 loss_) external onlyValidLiquidityPoolAdapter;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`loss_`|`uint256`|the requested amount of the asset with respect to the asset multiplier|


### _getPoolMultipliers

*Returns all pool multipliers and the sum of all pool multipliers*


```solidity
function _getPoolMultipliers()
    private
    view
    returns (uint256[] memory multipliedPoolValues, uint256 totalMultipliedValues);
```

### _beforeTokenTransfer

*Overwrite of the ERC20 function. Includes a check if the user is able to transfer their shares, which
depends on if the last deposit time longer ago than the defaultLockTime.*


```solidity
function _beforeTokenTransfer(address from, address to, uint256) internal view override;
```

### addPool

Add pool with a lock time and a multiplier

*User receives the reward for the normal shares, and the reward for the locked shares additional to that.
This is why 10_00 will total to a x1.1 multiplier.*


```solidity
function addPool(uint40 lockTime_, uint16 multiplier_)
    external
    onlyOwner
    verifyPoolParameters(lockTime_, multiplier_)
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`lockTime_`|`uint40`|Deposit lock time in seconds|
|`multiplier_`|`uint16`|Multiplier that applies to the pool. 10_00 is multiplier of x1.1, 100_00 is x2.0.|


### updatePool

Updates a lock pool


```solidity
function updatePool(uint256 poolId_, uint40 lockTime_, uint16 multiplier_)
    external
    onlyOwner
    verifyPoolId(poolId_)
    verifyPoolParameters(lockTime_, multiplier_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`poolId_`|`uint256`|Id of the pool to update|
|`lockTime_`|`uint40`|Deposit lock time in seconds|
|`multiplier_`|`uint16`|Multiplier that applies to the pool. 10_00 is multiplier of x1.1, 100_00 is x2.0.|


### updateDefaultLockTime

Update default lock time


```solidity
function updateDefaultLockTime(uint256 defaultLockTime_) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`defaultLockTime_`|`uint256`|default lock time|


### _updateDefaultLockTime

Update default lock time


```solidity
function _updateDefaultLockTime(uint256 defaultLockTime_) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`defaultLockTime_`|`uint256`|default lock time|


### updateEarlyWithdrawalFee

Update early withdrawal fee


```solidity
function updateEarlyWithdrawalFee(uint256 earlyWithdrawalFee_) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`earlyWithdrawalFee_`|`uint256`|early withdrawal fee|


### _updateEarlyWithdrawalFee

Update early withdrawal fee


```solidity
function _updateEarlyWithdrawalFee(uint256 earlyWithdrawalFee_) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`earlyWithdrawalFee_`|`uint256`|early withdrawal fee|


### updateEarlyWithdrawalTime

Update early withdrawal time


```solidity
function updateEarlyWithdrawalTime(uint256 earlyWithdrawalTime_) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`earlyWithdrawalTime_`|`uint256`|early withdrawal time|


### _updateEarlyWithdrawalTime

Update early withdrawal time


```solidity
function _updateEarlyWithdrawalTime(uint256 earlyWithdrawalTime_) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`earlyWithdrawalTime_`|`uint256`|early withdrawal time|


### updateMinimumAmount

Update minimum amount


```solidity
function updateMinimumAmount(uint256 minimumAmount_) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`minimumAmount_`|`uint256`|minimum amount|


### _updateMinimumAmount

Update minimum amount


```solidity
function _updateMinimumAmount(uint256 minimumAmount_) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`minimumAmount_`|`uint256`|minimum amount|


### _updateUser


```solidity
function _updateUser(address user) private;
```

### _canTransfer


```solidity
function _canTransfer(address user) private view;
```

### _canWithdrawLps


```solidity
function _canWithdrawLps(address user) private view;
```

### _onlyValidLiquidityPoolAdapter


```solidity
function _onlyValidLiquidityPoolAdapter() private view;
```

### _verifyPoolId


```solidity
function _verifyPoolId(uint256 poolId) private view;
```

### _verifyPoolParameters


```solidity
function _verifyPoolParameters(uint256 lockTime, uint256 multiplier) private pure;
```

### updateUser


```solidity
modifier updateUser(address user);
```

### updateUserPoolDeposits


```solidity
modifier updateUserPoolDeposits(address user, uint256 poolId);
```

### canTransfer


```solidity
modifier canTransfer(address user);
```

### canWithdraw


```solidity
modifier canWithdraw(address user);
```

### verifyPoolId


```solidity
modifier verifyPoolId(uint256 poolId);
```

### verifyPoolParameters


```solidity
modifier verifyPoolParameters(uint256 lockTime, uint256 multiplier);
```

### onlyValidLiquidityPoolAdapter


```solidity
modifier onlyValidLiquidityPoolAdapter();
```

