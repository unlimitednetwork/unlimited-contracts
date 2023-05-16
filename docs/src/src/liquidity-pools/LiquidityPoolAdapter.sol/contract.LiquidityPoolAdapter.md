# LiquidityPoolAdapter
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/liquidity-pools/LiquidityPoolAdapter.sol)

**Inherits:**
[ILiquidityPoolAdapter](/src/interfaces/ILiquidityPoolAdapter.sol/contract.ILiquidityPoolAdapter.md), [UnlimitedOwnable](/src/shared/UnlimitedOwnable.sol/contract.UnlimitedOwnable.md), Initializable


## State Variables
### controller
Controller contract.


```solidity
IController public immutable controller;
```


### feeManager
Fee manager address.


```solidity
address public immutable feeManager;
```


### collateral
The token that is used as a collateral


```solidity
IERC20 public immutable collateral;
```


### maxPayoutProportion
Maximum payout proportion of the available liquidity

*Denominated in BPS*


```solidity
uint256 public maxPayoutProportion;
```


### liquidityPools
List of liquidity pools configurations used by the adapter


```solidity
LiquidityPoolConfig[] public liquidityPools;
```


## Functions
### constructor

Constructs the `LiquidityPoolAdapter` contract.


```solidity
constructor(IUnlimitedOwner unlimitedOwner_, IController controller_, address feeManager_, IERC20 collateral_)
    UnlimitedOwnable(unlimitedOwner_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`unlimitedOwner_`|`IUnlimitedOwner`|The address of the unlimited owner.|
|`controller_`|`IController`|The address of the controller.|
|`feeManager_`|`address`|The address of the fee manager.|
|`collateral_`|`IERC20`|The address of the collateral token.|


### initialize

Initializes the `LiquidityPoolAdapter` contract.


```solidity
function initialize(uint256 maxPayoutProportion_, LiquidityPoolConfig[] memory liquidityPools_)
    external
    onlyOwner
    initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`maxPayoutProportion_`|`uint256`|The maximum payout proportion of the available liquidity.|
|`liquidityPools_`|`LiquidityPoolConfig[]`|The list of liquidity pools configurations used by the adapter.|


### updateLiquidityPools

Update list of liquidity pools


```solidity
function updateLiquidityPools(LiquidityPoolConfig[] calldata liquidityPools_) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`liquidityPools_`|`LiquidityPoolConfig[]`|address and percentage of the liquidity pools|


### _updateLiquidityPools

Update list of liquidity pools


```solidity
function _updateLiquidityPools(LiquidityPoolConfig[] memory liquidityPools_) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`liquidityPools_`|`LiquidityPoolConfig[]`|address and percentage of the liquidity pools|


### updateMaxPayoutProportion

Update maximum proportion of available liquidity to payout at once


```solidity
function updateMaxPayoutProportion(uint256 maxPayoutProportion_) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`maxPayoutProportion_`|`uint256`|Maximum proportion payout value|


### _updateMaxPayoutProportion

Update maximum proportion of available liquidity to payout at once


```solidity
function _updateMaxPayoutProportion(uint256 maxPayoutProportion_) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`maxPayoutProportion_`|`uint256`|Maximum proportion payout value|


### availableLiquidity

returns the total amount of available liquidity

*Sums up the liquidity of all liquidity pools allocated to this liquidity pool adapter*


```solidity
function availableLiquidity() public view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|availableLiquidity uint the available liquidity|


### getMaximumPayout

Returns maximum amount of available liquidity to payout at once


```solidity
function getMaximumPayout() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|maxPayout uint256 the maximum amount of available liquidity to payout at once|


### requestLossPayout

requests payout of a protocol loss when a trader made a profit

*pays out the user profit when msg.sender is a registered tradepair
and loss does not exceed the remaining liquidity.
Distributes loss to liquidity pools in respect to their allocated liquidity*


```solidity
function requestLossPayout(uint256 requestedPayout_) external onlyValidTradePair returns (uint256 actualPayout);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`requestedPayout_`|`uint256`|the requested payout amount|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`actualPayout`|`uint256`|Actual payout transferred to the trade pair|


### depositFees

deposits fees

*deposits fee when sender is FeeManager
The amount has to be sent to this LPA before calling this function.*


```solidity
function depositFees(uint256 feeAmount_) external onlyFeeManager;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`feeAmount_`|`uint256`|amount fees|


### depositProfit

deposits a protocol profit when a trader made a loss

*deposits profit when msg.sender is a registered tradepair
The amount has to be sent to this LPA before calling this function.*


```solidity
function depositProfit(uint256 profitAmount_) external onlyValidTradePair;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`profitAmount_`|`uint256`|the profit of the asset with respect to the asset multiplier|


### _depositToLiquidityPools

deposits assets to liquidity pools when a trader made a loss or fees are collected

*Distributes profit to liquidity pools in respect to their allocated liquidity
The amount has to be sent to this LPA before calling this function.*


```solidity
function _depositToLiquidityPools(uint256 amount_, bool isFees_) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount_`|`uint256`|the amount of the asset with respect to the asset multiplier|
|`isFees_`|`bool`|flag if the `amount` is fees|


### _depositToLiquidityPool


```solidity
function _depositToLiquidityPool(address liquidityPool_, uint256 amount_, bool isFees_) private;
```

### _onlyValidTradePair


```solidity
function _onlyValidTradePair() private view;
```

### _onlyFeeManager


```solidity
function _onlyFeeManager() private view;
```

### onlyValidTradePair


```solidity
modifier onlyValidTradePair();
```

### onlyFeeManager


```solidity
modifier onlyFeeManager();
```

