// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ISigImplementation} from "../interfaces/ISigImplementation.sol";

// Mock implementation of ISigImplementation
contract MockVerifier is ISigImplementation {
    bool private returnValue;

    function setReturnValue(
        bool value
    ) external {
        returnValue = value;
    }

    function verifySignature(
        address operator,
        bytes memory key,
        bytes memory signature
    ) external view override returns (bool) {
        // Simple mock implementation that returns pre-set value
        return returnValue;
    }
}
