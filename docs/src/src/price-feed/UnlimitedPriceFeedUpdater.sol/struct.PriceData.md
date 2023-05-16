# PriceData
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/price-feed/UnlimitedPriceFeedUpdater.sol)

Struct to store the price feed data.


```solidity
struct PriceData {
    uint32 createdOn;
    uint32 validTo;
    int192 price;
}
```

