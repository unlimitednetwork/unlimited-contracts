# FeeVolumes
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/user-manager/UserManager.sol)

Struct to store the volume limits to reach a new fee tier


```solidity
struct FeeVolumes {
    uint40 volume1;
    uint40 volume2;
    uint40 volume3;
    uint40 volume4;
    uint40 volume5;
    uint40 volume6;
}
```

