// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {HyveMiddleware} from "../../src/HyveMiddleware.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {BaseMiddlewareReader} from "@symbiotic-middleware/middleware/BaseMiddlewareReader.sol";

contract DeployHyveMiddleware is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.addr(deployerPrivateKey);
        address network = vm.envAddress("NETWORK_ADDRESS");
        address vaultRegistry = vm.envAddress("VAULT_REGISTRY");
        address operatorRegistry = vm.envAddress("OPERATOR_REGISTRY");
        address operatorNetOptIn = vm.envAddress("OPERATOR_NET_OPTIN");

        uint48 slashingWindow = 2 days;
        uint48 epochDuration = 2 days;

        vm.startBroadcast(deployerPrivateKey);

        BaseMiddlewareReader reader = new BaseMiddlewareReader();

        HyveMiddleware hyveMiddleware = new HyveMiddleware();

        bytes memory initData = abi.encodeWithSelector(
            HyveMiddleware.initialize.selector,
            network,
            slashingWindow,
            vaultRegistry,
            operatorRegistry,
            operatorNetOptIn,
            reader,
            owner,
            epochDuration
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(hyveMiddleware), initData);

        vm.stopBroadcast();
    }
}
