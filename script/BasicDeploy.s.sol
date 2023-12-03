// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// External Script Helpers
import {Script, console2} from "forge-std/Script.sol";

// Contracts
import {ClarityMarkets} from "../src/ClarityMarkets.sol";

// forge script ./script/BasicDeploy.s.sol --broadcast
// forge verify-contract ADDRESS ./src/ClarityMarkets.sol:ClarityMarkets --chain 84531 --watch

contract BasicDeployScript is Script {
    function run() public {
        bytes32 nacl = keccak256(abi.encodePacked(vm.envString("SALT")));
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);
        new ClarityMarkets{salt: nacl}();
        vm.stopBroadcast();
    }
}
