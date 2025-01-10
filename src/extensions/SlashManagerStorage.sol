// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ISlashStrategy} from "../interfaces/ISlashStrategy.sol";

/**
 * @title SlashManagerStorage
 * @notice A library that defines and manages the storage layout for SlashManager.
 *         This approach follows a common pattern (sometimes used in upgradeable or
 *         diamond-proxy contracts) to keep storage and logic separated.
 */
library SlashManagerStorage {
    /**
     * @dev Struct representing a recorded slash proof with its capture timestamp.
     * @param slashingProof Arbitrary data proving the slash event.
     * @param timestamp The timestamp or epoch when the slash was captured or finalized.
     */
    struct SlashInfo {
        bytes slashingProof;
        uint48 timestamp;
    }

    /**
     * @dev Primary storage layout for the SlashManager. This includes:
     * - A reference to the ISlashStrategy contract handling slash verification.
     * - A mapping for storing slash proof data, keyed by the operator/subnetwork/timestamp hash.
     */
    struct Layout {
        ISlashStrategy slashStrategy;
        mapping(bytes32 => SlashInfo) slashDataByKey;
    }

    /**
     * @dev keccak256(abi.encode(uint256(keccak256("hyve.storage.SlashEventStorage")) - 1)) & ~bytes32(uint256(0xff))
     */
    bytes32 internal constant STORAGE_SLOT = 0xf95168755ee872640a7084f15e608f333b75b6112b4cd5eeb6c7ef77aa0aa200;

    /**
     * @notice Returns a pointer to the library’s storage layout.
     * @return s The SlashManagerStorage.Layout struct in storage.
     */
    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }

    /**
     * @notice Sets the slash strategy contract in storage.
     * @param newStrategy The new ISlashStrategy to be used.
     */
    function setSlashStrategy(Layout storage s, ISlashStrategy newStrategy) internal {
        s.slashStrategy = newStrategy;
    }

    /**
     * @notice Fetches the configured slash strategy contract from storage.
     * @param s The SlashManagerStorage.Layout storage pointer.
     * @return The current slash strategy contract.
     */
    function getSlashStrategy(
        Layout storage s
    ) internal view returns (ISlashStrategy) {
        return s.slashStrategy;
    }

    /**
     * @notice Retrieves a previously stored slash proof for a given key.
     * @dev The key is typically derived with keccak256(abi.encodePacked(operator, subnetwork, timestamp)).
     * @param s The SlashManagerStorage.Layout storage pointer.
     * @param key The bytes32 key referencing slash data.
     * @return The stored SlashInfo (proof & timestamp).
     */
    function getSlashInfo(Layout storage s, bytes32 key) internal view returns (SlashInfo memory) {
        return s.slashDataByKey[key];
    }

    /**
     * @notice Stores slash information for a given key.
     * @param s The SlashManagerStorage.Layout storage pointer.
     * @param key The bytes32 key referencing slash data.
     * @param proof Arbitrary slash proof data.
     * @param captureTimestamp The timestamp or epoch of the slash event.
     */
    function storeSlashProof(Layout storage s, bytes32 key, bytes memory proof, uint48 captureTimestamp) internal {
        s.slashDataByKey[key] = SlashInfo({slashingProof: proof, timestamp: captureTimestamp});
    }
}
