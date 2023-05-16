# Controller
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/sys-controller/Controller.sol)

**Inherits:**
[IController](/src/interfaces/IController.sol/contract.IController.md), [UnlimitedOwnable](/src/shared/UnlimitedOwnable.sol/contract.UnlimitedOwnable.md)


## State Variables
### isTradePair
Is trade pair registered


```solidity
mapping(address => bool) public isTradePair;
```


### isLiquidityPool
Is liquidity pool registered


```solidity
mapping(address => bool) public isLiquidityPool;
```


### isLiquidityPoolAdapter
Is liquidity pool adapter registered


```solidity
mapping(address => bool) public isLiquidityPoolAdapter;
```


### isPriceFeed
Is price fee adapter registered


```solidity
mapping(address => bool) public isPriceFeed;
```


### isUpdatable
Is price fee adapter registered


```solidity
mapping(address => bool) public isUpdatable;
```


### isSigner
Is signer registered


```solidity
mapping(address => bool) public isSigner;
```


### isOrderExecutor
Is order executor registered


```solidity
mapping(address => bool) public isOrderExecutor;
```


### orderRewardOfCollateral
Returns order reward for collateral token

*Order reward is payed to executor of the order book (mainly Unlimited order book backend)
It is payed by a maker and added on top of the margin
Unlimited is collateral token agnostic, so the order reward can be different for different collaterals*


```solidity
mapping(address => uint256) public orderRewardOfCollateral;
```


## Functions
### constructor

Initializes immutable variables.


```solidity
constructor(IUnlimitedOwner unlimitedOwner_) UnlimitedOwnable(unlimitedOwner_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`unlimitedOwner_`|`IUnlimitedOwner`|UnlimitedOwner contract.|


### addTradePair

Adds the trade pair to the registry

*
Requirements:
- Caller must be owner.
- The contract must not be paused.
- Trade pair must be valid.*


```solidity
function addTradePair(address tradePair_)
    external
    onlyOwner
    onlyNonZeroAddress(tradePair_)
    onlyValidTradePair(tradePair_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tradePair_`|`address`|Trade pair address.|


### addLiquidityPool

Adds the liquidity pool to the registry

*
Requirements:
- Caller must be owner.
- The contract must not be paused.*


```solidity
function addLiquidityPool(address liquidityPool_) external onlyOwner onlyNonZeroAddress(liquidityPool_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`liquidityPool_`|`address`|Liquidity pool address.|


### addLiquidityPoolAdapter

Adds the liquidity pool adapter to the registry

*
Requirements:
- Caller must be owner.
- The contract must not be paused.*


```solidity
function addLiquidityPoolAdapter(address liquidityPoolAdapter_)
    external
    onlyOwner
    onlyNonZeroAddress(liquidityPoolAdapter_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`liquidityPoolAdapter_`|`address`|Liquidity pool adapter address.|


### addPriceFeed

Adds the price feed to the registry

*
Requirements:
- Caller must be owner.
- The contract must not be paused.*


```solidity
function addPriceFeed(address priceFeed_) external onlyOwner onlyNonZeroAddress(priceFeed_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`priceFeed_`|`address`|Price feed address.|


### addUpdatable

Adds an updatable contract to the registry


```solidity
function addUpdatable(address contractAddress_) external onlyOwner onlyNonZeroAddress(contractAddress_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`contractAddress_`|`address`|The address of the updatable contract|


### removeTradePair

Removes the trade pair from the registry

*
Requirements:
- Caller must be owner.
- The contract must not be paused.
- Trade pair must be already added.*


```solidity
function removeTradePair(address tradePair_) external onlyOwner onlyActiveTradePair(tradePair_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tradePair_`|`address`|Trade pair address.|


### removeLiquidityPool

Removes the liquidity pool from the registry

*
Requirements:
- Caller must be owner.
- The contract must not be paused.
- Liquidity pool must be already added.*


```solidity
function removeLiquidityPool(address liquidityPool_) external onlyOwner onlyActiveLiquidityPool(liquidityPool_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`liquidityPool_`|`address`|Liquidity pool address.|


### removeLiquidityPoolAdapter

Removes the liquidity pool adapter from the registry

*
Requirements:
- Caller must be owner.
- The contract must not be paused.
- Liquidity pool adapter must be already added.*


```solidity
function removeLiquidityPoolAdapter(address liquidityPoolAdapter_)
    external
    onlyOwner
    onlyActiveLiquidityPoolAdapter(liquidityPoolAdapter_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`liquidityPoolAdapter_`|`address`|Liquidity pool adapter address.|


### removePriceFeed

Removes the price feed from the registry

*
Requirements:
- Caller must be owner.
- The contract must not be paused.
- Price feed must be already added.*


```solidity
function removePriceFeed(address priceFeed_) external onlyOwner onlyActivePriceFeed(priceFeed_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`priceFeed_`|`address`|Price feed address.|


### removeUpdatable

Removes an updatable contract from the registry


```solidity
function removeUpdatable(address contractAddress_) external onlyOwner onlyNonZeroAddress(contractAddress_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`contractAddress_`|`address`|The address of the updatable contract|


### setOrderRewardOfCollateral

Sets order reward for collateral


```solidity
function setOrderRewardOfCollateral(address collateral_, uint256 orderReward_)
    external
    onlyOwner
    onlyNonZeroAddress(collateral_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateral_`|`address`|address of the collateral token|
|`orderReward_`|`uint256`|order reward (in decimals of collateral token)|


### checkTradePairActive

Reverts if trade pair inactive


```solidity
function checkTradePairActive(address tradePair_) external view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tradePair_`|`address`|trade pair address|


### addSigner

Function to add a valid signer


```solidity
function addSigner(address signer_) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`signer_`|`address`|address of the signer|


### removeSigner

Function to remove a valid signer


```solidity
function removeSigner(address signer_) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`signer_`|`address`|address of the signer|


### addOrderExecutor

Function to add a valid order executor


```solidity
function addOrderExecutor(address orderExecutor_) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`orderExecutor_`|`address`|address of the order executor|


### removeOrderExecutor

Function to remove a valid order executor


```solidity
function removeOrderExecutor(address orderExecutor_) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`orderExecutor_`|`address`|address of the order executor|


### _onlyActiveTradePair

*Reverts when TradePair is not active*


```solidity
function _onlyActiveTradePair(address tradePair_) private view;
```

### _onlyActiveLiquidityPool

*Reverts when LiquidityPool is not valid*


```solidity
function _onlyActiveLiquidityPool(address liquidityPool_) private view;
```

### _onlyActiveLiquidityPoolAdapter

*Reverts when LiquidityPoolAdapter is not valid*


```solidity
function _onlyActiveLiquidityPoolAdapter(address liquidityPoolAdapter_) private view;
```

### _onlyActivePriceFeed

*Reverts when PriceFeed is not valid*


```solidity
function _onlyActivePriceFeed(address priceFeed_) private view;
```

### _onlyValidTradePair

*Reverts when the TradePair is not active or has an invalid liquidity pool*


```solidity
function _onlyValidTradePair(ITradePair tradePair_) private view;
```

### _onlyNonZeroAddress

*Reverts when address is zero address*


```solidity
function _onlyNonZeroAddress(address address_) private pure;
```

### onlyActiveTradePair

Reverts if trade pair not in the registry


```solidity
modifier onlyActiveTradePair(address tradePair_);
```

### onlyActiveLiquidityPool

Reverts if liquidity pool not in the registry


```solidity
modifier onlyActiveLiquidityPool(address liquidityPool_);
```

### onlyActiveLiquidityPoolAdapter

Reverts if liquidity pool adapter not in the registry


```solidity
modifier onlyActiveLiquidityPoolAdapter(address liquidityPoolAdapter_);
```

### onlyActivePriceFeed

Reverts if price feed not in the registry


```solidity
modifier onlyActivePriceFeed(address priceFeed_);
```

### onlyValidTradePair

Reverts if trade pair invalid - i.e. its price feed or liquidity pool adapter are not registered
in the system.


```solidity
modifier onlyValidTradePair(address tradePair_);
```

### onlyNonZeroAddress

Reverts if give address is 0


```solidity
modifier onlyNonZeroAddress(address address_);
```

