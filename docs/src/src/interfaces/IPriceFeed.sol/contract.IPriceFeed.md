# IPriceFeed
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/interfaces/IPriceFeed.sol)

Gets the last and previous price of an asset from a price feed

*The price must be returned with 8 decimals, following the USD convention*


## Functions
### price


```solidity
function price() external view returns (int256);
```

