# IPriceFeedAggregator
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/interfaces/IPriceFeedAggregator.sol)

Aggreates two or more price feeds into min and max prices


## Functions
### name


```solidity
function name() external view returns (string memory);
```

### minPrice


```solidity
function minPrice() external view returns (int256);
```

### maxPrice


```solidity
function maxPrice() external view returns (int256);
```

### addPriceFeed


```solidity
function addPriceFeed(IPriceFeed) external;
```

### removePriceFeed


```solidity
function removePriceFeed(uint256) external;
```

