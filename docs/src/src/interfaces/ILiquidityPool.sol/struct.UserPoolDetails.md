# UserPoolDetails
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/interfaces/ILiquidityPool.sol)

Struct to be returned by view functions to inform about locked and unlocked pool shares of a user


```solidity
struct UserPoolDetails {
    uint256 poolId;
    uint256 totalPoolShares;
    uint256 unlockedPoolShares;
    uint256 totalShares;
    uint256 unlockedShares;
    uint256 totalAssets;
    uint256 unlockedAssets;
}
```

