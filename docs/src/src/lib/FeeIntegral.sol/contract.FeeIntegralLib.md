# FeeIntegralLib
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/lib/FeeIntegral.sol)

Provides data structures and functions for calculating the fee integrals

*This contract is a library and should be used by a contract that implements the ITradePair interface*


## Functions
### update

update fee integrals

*Update needs to happen before volumes change.*


```solidity
function update(FeeIntegral storage _self, uint256 longVolume, uint256 shortVolume) external;
```

### getCurrentFundingFeeIntegrals

get current funding fee integrals


```solidity
function getCurrentFundingFeeIntegrals(FeeIntegral storage _self, uint256 longVolume, uint256 shortVolume)
    external
    view
    returns (int256, int256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_self`|`FeeIntegral`||
|`longVolume`|`uint256`|long position volume|
|`shortVolume`|`uint256`|short position volume|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`int256`|longFundingFeeIntegral long funding fee integral|
|`<none>`|`int256`|shortFundingFeeIntegral short funding fee integral|


### getCurrentBorrowFeeIntegral

get current borrow fee integral

*calculated by stored integral + elapsed integral*


```solidity
function getCurrentBorrowFeeIntegral(FeeIntegral storage _self) external view returns (int256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`int256`|borrowFeeIntegral current borrow fee integral|


### getElapsedBorrowFeeIntegral

get the borrow fee integral since last update


```solidity
function getElapsedBorrowFeeIntegral(FeeIntegral storage _self) external view returns (int256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`int256`|borrowFeeIntegral borrow fee integral since last update|


### getCurrentFundingFeeRates

Calculates the current funding fee rates


```solidity
function getCurrentFundingFeeRates(FeeIntegral storage _self, uint256 longVolume, uint256 shortVolume)
    external
    view
    returns (int256, int256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_self`|`FeeIntegral`||
|`longVolume`|`uint256`|long position volume|
|`shortVolume`|`uint256`|short position volume|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`int256`|longFundingFeeRate long funding fee rate|
|`<none>`|`int256`|shortFundingFeeRate short funding fee rate|


### _updateBorrowFeeIntegral

========== INTERNAL FUNCTIONS ==========

update the integral of borrow fee calculated since last update


```solidity
function _updateBorrowFeeIntegral(FeeIntegral storage _self) internal;
```

### _getElapsedBorrowFeeIntegral

get the borrow fee integral since last update


```solidity
function _getElapsedBorrowFeeIntegral(FeeIntegral storage _self) internal view returns (int256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`int256`|borrowFeeIntegral borrow fee integral since last update|


### _updateFundingFeeIntegrals

update the integrals of funding fee calculated since last update

*the integrals can be negative, when one side pays the other.
longVolume and shortVolume can also be sizes, the ratio is important.*


```solidity
function _updateFundingFeeIntegrals(FeeIntegral storage _self, uint256 longVolume, uint256 shortVolume) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_self`|`FeeIntegral`||
|`longVolume`|`uint256`|volume of long positions|
|`shortVolume`|`uint256`|volume of short positions|


### _getElapsedFundingFeeIntegrals

get the integral of funding fee calculated since last update

*the integrals can be negative, when one side pays the other.
longVolume and shortVolume can also be sizes, the ratio is important.*


```solidity
function _getElapsedFundingFeeIntegrals(FeeIntegral storage _self, uint256 longVolume, uint256 shortVolume)
    internal
    view
    returns (int256, int256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_self`|`FeeIntegral`||
|`longVolume`|`uint256`|volume of long positions|
|`shortVolume`|`uint256`|volume of short positions|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`int256`|elapsedLongIntegral integral of long funding fee|
|`<none>`|`int256`|elapsedShortIntegral integral of short funding fee|


