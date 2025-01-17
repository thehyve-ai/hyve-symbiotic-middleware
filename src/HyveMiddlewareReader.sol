// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {BaseMiddlewareReader} from "@symbiotic-middleware/middleware/BaseMiddlewareReader.sol";
import {HyveMiddleware} from "./HyveMiddleware.sol";

/**
 * @title HyveMiddlewareReader
 * @notice A helper contract extending BaseMiddlewareReader with additional view functions for Hyve middleware
 */
contract HyveMiddlewareReader is BaseMiddlewareReader {}
