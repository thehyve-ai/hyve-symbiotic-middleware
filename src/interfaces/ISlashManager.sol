// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ISlashStrategy} from "./ISlashStrategy.sol";

/**
 * @title ISlashManager
 * @notice Interface for a contract that coordinates operator slashing across multiple vaults and subnetworks.
 */
interface ISlashManager {
    /**
     * @notice Thrown when the hints arrays provided to slash() are misaligned or invalid.
     */
    error InvalidHints();

    /**
     * @notice Thrown when a slash is attempted for a key (operator + subnetwork + timestamp) that already exists.
     */
    error AlreadySlashed();

    /**
     * @notice Emitted when the slash strategy contract is updated.
     * @param oldStrategy The old slash strategy contract address.
     * @param newStrategy The new slash strategy contract address.
     */
    event SlashStrategyUpdated(address indexed oldStrategy, address indexed newStrategy);

    /**
     * @notice Changes the slash strategy (must pass any necessary access control).
     * @param newStrategy The new ISlashStrategy contract address.
     */
    function setSlashStrategy(
        ISlashStrategy newStrategy
    ) external;

    /**
     * @notice Retrieves stored slash proof data and timestamp for a given operator, subnetwork, and capture timestamp.
     * @param operator The operator's address.
     * @param subnetwork The subnetwork identifier (as bytes32).
     * @param captureTimestamp The recorded timestamp (or epoch).
     * @return slashingProof The proof data (arbitrary bytes).
     * @return storedTimestamp The timestamp when the slash was recorded.
     */
    function getSlashInfo(
        address operator,
        bytes32 subnetwork,
        uint48 captureTimestamp
    ) external view returns (bytes memory slashingProof, uint48 storedTimestamp);

    /**
     * @notice Main slash function. Validates a slash, then slashes across each vault/subnetwork.
     * @param operator The operator to be slashed.
     * @param amount Total slash amount for the chosen operator.
     * @param slashProof Arbitrary data representing the slash proof (e.g., signature or merkle proof).
     * @param stakeHints Hints used by each vault for calculating stake at a given subnetwork.
     * @param slashHints Additional hints used for the slashing process by each vault.
     */
    function slash(
        address operator,
        uint256 amount,
        bytes calldata slashProof,
        bytes[][] memory stakeHints,
        bytes[] memory slashHints
    ) external;
}
