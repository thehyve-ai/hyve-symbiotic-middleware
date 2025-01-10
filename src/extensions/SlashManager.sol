// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {BaseMiddleware} from "@symbiotic-middleware/middleware/BaseMiddleware.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IBaseDelegator} from "@symbiotic/interfaces/delegator/IBaseDelegator.sol";
import {IVault} from "@symbiotic/interfaces/vault/IVault.sol";
import {Subnetwork} from "@symbiotic/contracts/libraries/Subnetwork.sol";

import {ISlashStrategy} from "../interfaces/ISlashStrategy.sol";
import {ISlashManager} from "../interfaces/ISlashManager.sol";
import {SlashManagerStorage} from "./SlashManagerStorage.sol";

/**
 * @title Slash Manager
 * @notice This contract handles the slashing of operators. It is split so that
 *         storage is managed separately by the SlashManagerStorage library,
 *         following an upgrade-safe design (common in EIP-2535 Diamonds or proxy-based upgrades).
 */
abstract contract SlashManager is BaseMiddleware, ISlashManager {
    using Subnetwork for address;

    /**
     * @notice Changes the slash strategy (must pass the custom checkAccess).
     * @param newStrategy The new ISlashStrategy contract address.
     */
    function setSlashStrategy(
        ISlashStrategy newStrategy
    ) external checkAccess {
        address oldStrategy = address(SlashManagerStorage.layout().slashStrategy);
        SlashManagerStorage.setSlashStrategy(SlashManagerStorage.layout(), newStrategy);
        emit SlashStrategyUpdated(oldStrategy, address(newStrategy));
    }

    function getSlashStrategy() external view returns (address) {
        return address(SlashManagerStorage.layout().slashStrategy);
    }

    /**
     * @inheritdoc ISlashManager
     */
    function getSlashInfo(
        address operator,
        bytes32 subnetwork,
        uint48 captureTimestamp
    ) external view returns (bytes memory slashingProof, uint48 storedTimestamp) {
        bytes32 key = _slashKey(operator, subnetwork, captureTimestamp);
        SlashManagerStorage.SlashInfo memory info = SlashManagerStorage.getSlashInfo(SlashManagerStorage.layout(), key);
        return (info.slashingProof, info.timestamp);
    }

    /**
     * @notice Main slash function. Calls the slash strategy for validation, then iterates
     *         over each vault and subnetwork to proportionally distribute a slash.
     * @param operator The operator to be slashed.
     * @param amount Total slash amount for the chosen operator.
     * @param slashProof Arbitrary data representing the slash proof (e.g., signature, proof).
     * @param stakeHints Hints used by each vault for calculating stake at a given subnetwork.
     * @param slashHints Additional hints used for the slashing process by each vault.
     */
    function slash(
        address operator,
        uint256 amount,
        bytes calldata slashProof,
        bytes[][] memory stakeHints,
        bytes[] memory slashHints
    ) external {
        // 1. Validate the slash via the slash strategy contract.
        ISlashStrategy.SlashParams memory slashParams = _verifySlash(operator, amount, slashProof);

        uint256 vaultsLength = slashParams.vaults.length;
        uint256 subnetworksLength = slashParams.subnetworks.length;

        // 2. Validate the lengths of the hint arrays.
        if (stakeHints.length != vaultsLength || stakeHints.length != slashHints.length) {
            revert InvalidHints();
        }

        // 3. Perform slash across each vault / subnetwork combination.
        for (uint256 i; i < vaultsLength; ++i) {
            if (stakeHints[i].length != subnetworksLength) {
                revert InvalidHints();
            }
            address vault = slashParams.vaults[i];

            for (uint256 j; j < subnetworksLength; ++j) {
                bytes32 subnetwork = _NETWORK().subnetwork(uint96(slashParams.subnetworks[j]));

                // (a) Calculate the operator’s stake at capture time for subnetwork & operator.
                uint256 stake = IBaseDelegator(IVault(vault).delegator()).stakeAt(
                    subnetwork, slashParams.operator, slashParams.captureTimestamp, stakeHints[i][j]
                );

                // (b) Pro-rate the slash amount by the operator’s stake power on that vault/subnetwork.
                uint256 slashAmount = Math.mulDiv(amount, stakeToPower(vault, stake), slashParams.totalPower);

                // (c) If slash portion is > 0, slash from the vault.
                if (slashAmount > 0) {
                    _slashVault(
                        slashParams.captureTimestamp,
                        vault,
                        subnetwork,
                        slashParams.operator,
                        slashAmount,
                        slashHints[i]
                    );
                }

                // (d) Store slashing proof for each subnetwork, once per unique key.
                _storeSlashProofOnce(slashParams.operator, subnetwork, slashParams.captureTimestamp, slashProof);
            }
        }
    }

    /**
     * @notice Internal helper to generate the storage key for slash data.
     * @param operator The operator address.
     * @param subnetwork The subnetwork identifier (as bytes32).
     * @param captureTimestamp The timestamp or epoch used in slashing.
     */
    function _slashKey(address operator, bytes32 subnetwork, uint48 captureTimestamp) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(operator, subnetwork, captureTimestamp));
    }

    /**
     * @notice Internal function that calls the slash strategy to validate the slash.
     * @param operator The operator to be slashed.
     * @param amount The amount to slash.
     * @param data Arbitrary slash data used by the strategy (e.g. signature, proof).
     */
    function _verifySlash(
        address operator,
        uint256 amount,
        bytes calldata data
    ) internal view returns (ISlashStrategy.SlashParams memory) {
        // Retrieve slash strategy from library storage
        ISlashStrategy s = SlashManagerStorage.getSlashStrategy(SlashManagerStorage.layout());
        return s.verifySlash(operator, amount, data);
    }

    /**
     * @notice Internal function that stores the slash proof once for each (operator, subnetwork, timestamp).
     * @dev does not revert if the slash proof is already recorded. The verifier should check this.
     * @param operator The operator to be slashed.
     * @param subnetwork The subnetwork identifier (as bytes32).
     * @param captureTimestamp The capture timestamp.
     * @param slashProof Arbitrary slash proof data to store.
     */
    function _storeSlashProofOnce(
        address operator,
        bytes32 subnetwork,
        uint48 captureTimestamp,
        bytes calldata slashProof
    ) internal {
        bytes32 key = _slashKey(operator, subnetwork, captureTimestamp);

        // Store the slash proof
        SlashManagerStorage.storeSlashProof(SlashManagerStorage.layout(), key, slashProof, captureTimestamp);
    }
}
