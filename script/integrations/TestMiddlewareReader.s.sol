// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console2} from "forge-std/Script.sol";
import {BaseMiddlewareReader} from "@symbiotic-middleware/middleware/BaseMiddlewareReader.sol";
import {IBaseMiddlewareReader} from "@symbiotic-middleware/interfaces/IBaseMiddlewareReader.sol";

contract TestMiddlewareReader is Script {
    function run() external {
        // Address of the deployed middleware on Sepolia
        address MIDDLEWARE = 0xBf3e64f0f83d5ce7f9BfFA0eE7Ec524e9999D572;

        // Create interface to make calls
        IBaseMiddlewareReader middlewareReader = IBaseMiddlewareReader(MIDDLEWARE);

        // Test some view functions
        console2.log("Testing reader functions:");

        console2.log("Network address:", middlewareReader.NETWORK());
        console2.log("Slashing window:", middlewareReader.SLASHING_WINDOW());
        console2.log("Vault registry:", middlewareReader.VAULT_REGISTRY());
        console2.log("Operator registry:", middlewareReader.OPERATOR_REGISTRY());

        // Get operators length
        uint256 opsLength = middlewareReader.operatorsLength();
        console2.log("Number of operators:", opsLength);

        // Get active operators
        address[] memory activeOps = middlewareReader.activeOperators();
        console2.log("Number of active operators:", activeOps.length);
        for (uint256 i = 0; i < activeOps.length; i++) {
            console2.log("Active operator", i, ":", activeOps[i]);
        }
    }
}
