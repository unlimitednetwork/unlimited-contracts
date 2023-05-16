# IUserManager
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/interfaces/IUserManager.sol)


## Functions
### addUserVolume


```solidity
function addUserVolume(address user, uint40 volume) external;
```

### setUserReferrer


```solidity
function setUserReferrer(address user, address referrer) external;
```

### setUserManualTier


```solidity
function setUserManualTier(address user, Tier tier, uint32 validUntil) external;
```

### setFeeVolumes


```solidity
function setFeeVolumes(uint256[] calldata feeIndexes, uint32[] calldata feeVolumes) external;
```

### setFeeSizes


```solidity
function setFeeSizes(uint256[] calldata feeIndexes, uint8[] calldata feeSizes) external;
```

### getUserFee


```solidity
function getUserFee(address user) external view returns (uint256);
```

### getUserReferrer


```solidity
function getUserReferrer(address user) external view returns (address referrer);
```

## Events
### FeeSizeUpdated

```solidity
event FeeSizeUpdated(uint256 indexed feeIndex, uint256 feeSize);
```

### FeeVolumeUpdated

```solidity
event FeeVolumeUpdated(uint256 indexed feeIndex, uint256 feeVolume);
```

### UserVolumeAdded

```solidity
event UserVolumeAdded(address indexed user, address indexed tradePair, uint256 volume);
```

### UserManualTierUpdated

```solidity
event UserManualTierUpdated(address indexed user, Tier tier, uint256 validUntil);
```

### UserReferrerAdded

```solidity
event UserReferrerAdded(address indexed user, address referrer);
```

