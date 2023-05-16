# UnlimitedPriceFeed
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/price-feed/UnlimitedPriceFeed.sol)

**Inherits:**
[IPriceFeed](/src/interfaces/IPriceFeed.sol/contract.IPriceFeed.md), [IUpdatable](/src/interfaces/IUpdatable.sol/contract.IUpdatable.md), [UnlimitedOwnable](/src/shared/UnlimitedOwnable.sol/contract.UnlimitedOwnable.md)

Unlimited Price Feed is a price feed that can be updated by anyone.
To update the price feed, the caller must provide a UpdateData struct that contains
a valid signature from the registered signer. Price Updates contained must by valid and more recent than
the last update. The price feed will only accept updates that are within the validTo period.
The price may only deviate at a set percentage from the chainlink price feed.


## State Variables
### WORD_LENGTH

```solidity
uint256 private constant WORD_LENGTH = 32;
```


### SIGNATURE_END

```solidity
uint256 private constant SIGNATURE_END = 65;
```


### SIGNER_END

```solidity
uint256 private constant SIGNER_END = SIGNATURE_END + WORD_LENGTH;
```


### DATA_LENGTH

```solidity
uint256 private constant DATA_LENGTH = SIGNER_END + WORD_LENGTH * 3;
```


### MINIMUM_MAX_DEVIATION
Minimum value that can be set for max deviation.


```solidity
uint256 constant MINIMUM_MAX_DEVIATION = 5;
```


### controller
Controller contract.


```solidity
IController public immutable controller;
```


### chainlinkPriceFeed
PriceFeed against which the price is compared. Only a maximum deviation is allowed.


```solidity
AggregatorV2V3Interface public immutable chainlinkPriceFeed;
```


### maxDeviation
Maximum deviation from the chainlink price feed


```solidity
uint256 public maxDeviation;
```


### priceData
Recent price data. It gets updated with each valid update request.


```solidity
PriceData public priceData;
```


## Functions
### constructor

Constructs the UnlimitedPriceFeed contract.


```solidity
constructor(
    IUnlimitedOwner unlimitedOwner_,
    AggregatorV2V3Interface chainlinkPriceFeed_,
    IController controller_,
    uint256 maxDeviation_
) UnlimitedOwnable(unlimitedOwner_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`unlimitedOwner_`|`IUnlimitedOwner`|The address of the unlimited owner.|
|`chainlinkPriceFeed_`|`AggregatorV2V3Interface`|The address of the Chainlink price feed.|
|`controller_`|`IController`|The address of the controller contract.|
|`maxDeviation_`|`uint256`|The maximum deviation from the chainlink price feed.|


### price

Returns last price


```solidity
function price() public view verifyPriceValidity returns (int256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`int256`|the price from the last round|


### update

Update price with signed data.


```solidity
function update(bytes calldata updateData_) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`updateData_`|`bytes`|Data bytes consisting of signature, signer and price data in respected order.|


### updateMaxDeviation

Updates the maximum deviation from the chainlink price feed.


```solidity
function updateMaxDeviation(uint256 maxDeviation_) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`maxDeviation_`|`uint256`|The new maximum deviation.|


### _hashPriceDataUpdate


```solidity
function _hashPriceDataUpdate(PriceData memory priceData_) internal view returns (bytes32);
```

### _updateMaxDeviation


```solidity
function _updateMaxDeviation(uint256 maxDeviation_) private;
```

### _verifyValidTo


```solidity
function _verifyValidTo(uint256 validTo_) private view;
```

### _verifySigner


```solidity
function _verifySigner(address signer_) private view;
```

### verifyPriceValidity


```solidity
modifier verifyPriceValidity();
```

