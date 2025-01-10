// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {BaseMiddlewareReader} from "@symbiotic-middleware/middleware/BaseMiddlewareReader.sol";
import {HyveMiddleware} from "./HyveMiddleware.sol";
/**
 * @title BaseMiddlewareReader
 * @notice A helper contract for view functions that combines core manager functionality
 * @dev This contract serves as a foundation for building custom middleware by providing essential
 * management capabilities that can be extended with additional functionality.
 */

contract HyveMiddlewareReader is BaseMiddlewareReader {
    function getSlashInfo(
        address operator,
        bytes32 subnetwork,
        uint48 captureTimestamp
    ) external view returns (bytes memory slashingProof, uint48 storedTimestamp) {
        return HyveMiddleware(_getHyveMiddleware()).getSlashInfo(operator, subnetwork, captureTimestamp);
    }

    function getSlashStrategy() external view returns (address) {
        return HyveMiddleware(_getHyveMiddleware()).getSlashStrategy();
    }

    /**
     * @notice Gets the middleware address from the calldata
     * @return The middleware address
     */
    function _getHyveMiddleware() private pure returns (address) {
        address middleware;
        assembly {
            middleware := shr(96, calldataload(sub(calldatasize(), 20)))
        }
        return middleware;
    }
}
