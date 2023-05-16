# UnlimitedPriceFeedUpdater
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/price-feed/UnlimitedPriceFeedUpdater.sol)

**Inherits:**
[IUpdatable](/src/interfaces/IUpdatable.sol/contract.IUpdatable.md)

Unlimited Price Feed is a price feed that can be updated by anyone.
To update the price feed, the caller must provide a UpdateData struct that contains
a valid signature from the registered signer. Price Updates contained must by valid and more recent than
the last update. The price feed will only accept updates that are within the validTo period.
The price may only deviate at a set percentage from the chainlink price feed.


## State Variables
### SIGNATURE_END

```solidity
uint256 private constant SIGNATURE_END = 65;
```


### WORD_LENGTH

```solidity
uint256 private constant WORD_LENGTH = 32;
```


### SIGNER_END

```solidity
uint256 private constant SIGNER_END = SIGNATURE_END + WORD_LENGTH;
```


### DATA_LENGTH

```solidity
uint256 private constant DATA_LENGTH = SIGNER_END + WORD_LENGTH * 3;
```


### controller
Controller contract.


```solidity
IController public immutable controller;
```


### priceDecimals
Price decimals.


```solidity
uint256 public priceDecimals;
```


### _priceMultiplier
Price multiplier.


```solidity
uint256 internal _priceMultiplier;
```


### priceData
Recent price data. It gets updated with each valid update request.


```solidity
PriceData public priceData;
```


## Functions
### constructor

Constructs the UnlimitedPriceFeedUpdater contract.


```solidity
constructor(IController controller_, uint256 priceDecimals_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`controller_`|`IController`|The address of the controller contract.|
|`priceDecimals_`|`uint256`|Decimal places in a price.|


### _price

Returns last price


```solidity
function _price() internal view verifyPriceValidity returns (int256);
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


### _hashPriceDataUpdate


```solidity
function _hashPriceDataUpdate(PriceData memory priceData_) internal view returns (bytes32);
```

### _verifyNewPrice


```solidity
function _verifyNewPrice(int256 newPrice) internal view virtual;
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

