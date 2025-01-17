// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ISelfRegisterOperators} from "@symbiotic-middleware/interfaces/extensions/operators/ISelfRegisterOperators.sol";

interface IOperatorRegistry {
    struct Keys {
        bytes bls;
        bytes p2p;
    }

    function registerOperator(
        address operator,
        bytes memory keys,
        address vault,
        bytes memory signature,
        bytes memory keySignature
    ) external;
}
