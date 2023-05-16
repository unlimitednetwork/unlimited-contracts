# FeeIntegral
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/lib/FeeIntegral.sol)

Struct to store the fee integral values


```solidity
struct FeeIntegral {
    int256 longFundingFeeIntegral;
    int256 shortFundingFeeIntegral;
    int256 fundingFeeRate;
    int256 maxExcessRatio;
    int256 borrowFeeIntegral;
    int256 borrowFeeRate;
    uint256 lastUpdatedAt;
}
```

