# FundingFee
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/lib/FundingFee.sol)

Library for calculating funding fees

*Funding fees are the "long pays short" fees. They are calculated based on the excess volume of long positions over short positions or vice-versa.
Funding fees are calculated using a curve function. The curve function resembles a logarithmic growth function, but is easier to calculate.*


## State Variables
### ONE

```solidity
int256 constant ONE = FEE_MULTIPLIER;
```


### TWO

```solidity
int256 constant TWO = 2 * ONE;
```


### PERCENT

```solidity
int256 constant PERCENT = ONE / 100;
```


## Functions
### getFundingFeeRates

calculates the fee rates for long and short positions.


```solidity
function getFundingFeeRates(uint256 longVolume, uint256 shortVolume, int256 maxRatio, int256 maxFeeRate)
    public
    pure
    returns (int256 longFeeRate, int256 shortFeeRate);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`longVolume`|`uint256`|the volume of long positions|
|`shortVolume`|`uint256`|the volume of short positions|
|`maxRatio`|`int256`|the maximum ratio of excess volume to deficient volume. All excess volume above this ratio will be ignored.|
|`maxFeeRate`|`int256`|the maximum fee rate that can be charged.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`longFeeRate`|`int256`|(int256) the fee for long positions.|
|`shortFeeRate`|`int256`|(int256) the fee for short positions.|


### normalizedExcessRatio

calculates the normalized excess volume


```solidity
function normalizedExcessRatio(uint256 excessVolume, uint256 deficientVolume, int256 maxRatio)
    public
    pure
    onlyPositiveVolumeExcess(excessVolume, deficientVolume)
    returns (int256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`excessVolume`|`uint256`|the excess volume|
|`deficientVolume`|`uint256`|the deficient volume|
|`maxRatio`|`int256`|the maximum ratio of excess volume to deficient volume. Denominated in ONE. When the ratio is higher than this value, the return value is ONE.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`int256`|the normalized excess volume to be used in the curve. Denominated like ONE.|


### curve

Curve to calculate the balance fee
The curve resembles a logarithmic growth function, but is easier to calculate.
Function starts at zero and goes to one.
Function has a soft ease-in-ease-out.
1|-------------------
.|           ~°°°
.|        +´
.|       /
.|    +´
.|_~°°
0+-------------------
#0                  1
Function:
y = 0; x <= 0;
y = ((2x)**2)/2; 0 <= x < 0.5;
y = (2-(2-2x)**2)/2; 0.5 <= x < 1;
y = 1; 1 <= x;
Represents concave function starting at (0,0) and reaching the max value
and a slope of 0 at (1/1)


```solidity
function curve(int256 x) public pure returns (int256 y);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`x`|`int256`|needs to have decimals of PERCENT|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`y`|`int256`|y|


### calculateFundingFee

Calculates the funding fee


```solidity
function calculateFundingFee(int256 normalizedFeeValue, int256 maxFee) public pure returns (int256 fee);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`normalizedFeeValue`|`int256`|the normalized fee value between 0 and ONE. Denominated in PERCENT.|
|`maxFee`|`int256`|the maximum fee. Denominated in PERCENT|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`fee`|`int256`|the funding fee. Denominated in PERCENT|


### calculateFundingFeeReward

calculates the funding reward. The funding reward is the fee that is paid to the "other" position.

*It is calculated by distributing the total collected funding fee to the "other" positions based on their share of the total volume.*


```solidity
function calculateFundingFeeReward(uint256 excessVolume, uint256 deficientVolume, int256 fee)
    public
    pure
    onlyPositiveVolumeExcess(excessVolume, deficientVolume)
    returns (int256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`excessVolume`|`uint256`|the excess volume|
|`deficientVolume`|`uint256`|the deficient volume|
|`fee`|`int256`|the relative fee for the excess volume. Denominated in PERCENT|


### onlyPositiveVolumeExcess

checks if excessVolume is higher than deficientVolume


```solidity
modifier onlyPositiveVolumeExcess(uint256 excessVolume, uint256 deficientVolume);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`excessVolume`|`uint256`|the excess volume|
|`deficientVolume`|`uint256`|the deficient volume|


