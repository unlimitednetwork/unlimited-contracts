// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "script/Deploy.s.sol";
import "forge-std/Script.sol";

contract DeployArbitrumGoerli is Script {
    function run() public {
        string memory _network = "arbitrum-goerli";

        DeployScript deployScript = new DeployScript();
        deployScript.setNetwork(_network);
        deployScript.run();
    }
}
