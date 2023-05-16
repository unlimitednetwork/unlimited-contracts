# UserPoolInfo
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/liquidity-pools/LiquidityPool.sol)

Aggregated Info about a users locked shares in a lock pool


```solidity
struct UserPoolInfo {
    uint256 userPoolShares;
    uint256 unlockedPoolShares;
    uint128 nextIndex;
    uint128 length;
    mapping(uint256 => UserPoolDeposit) deposits;
}
```

