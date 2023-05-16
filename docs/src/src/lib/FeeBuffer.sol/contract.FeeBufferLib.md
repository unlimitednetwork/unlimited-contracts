# FeeBufferLib
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/lib/FeeBuffer.sol)

Stores and operates on the fee buffer. Calculates possible fee losses.

*This contract is a library and should be used by a contract that implements the ITradePair interface*


## Functions
### clearBuffer

clears fee buffer for a given position. Either ´remainingBuffer´ is positive OR ´requestLoss´ is positive.
When ´remainingBuffer´ is positive, then ´remainingMargin´ could also be possible.


```solidity
function clearBuffer(FeeBuffer storage _self, uint256 _margin, int256 _borrowFeeAmount, int256 _fundingFeeAmount)
    public
    returns (uint256 remainingMargin, uint256 remainingBuffer, uint256 requestLoss);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_self`|`FeeBuffer`||
|`_margin`|`uint256`|the margin of the position|
|`_borrowFeeAmount`|`int256`|amount of borrow fee|
|`_fundingFeeAmount`|`int256`|amount of funding fee|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`remainingMargin`|`uint256`|the _margin of the position after clearing the buffer and paying fees|
|`remainingBuffer`|`uint256`|remaining amount that needs to be transferred to the fee manager|
|`requestLoss`|`uint256`|the amount of loss that needs to be requested from the liquidity pool|


### takeBufferFrom

Takes buffer amount from the provided amount and returns reduced amount.


```solidity
function takeBufferFrom(FeeBuffer storage _self, uint256 _amount) public returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_self`|`FeeBuffer`||
|`_amount`|`uint256`|the amount to take buffer from|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|amount the amount after taking buffer|


