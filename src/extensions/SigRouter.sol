// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {SigManager} from "@symbiotic-middleware/managers/extendable/SigManager.sol";
import {ISigImplementation} from "../interfaces/ISigImplementation.sol";

/**
 * @title SigRouter
 * @notice A SigManager that supports multiple signature verification methods by routing
 *         verification requests to different implementations based on a version.
 */
abstract contract SigRouter is SigManager {
    error KeyTooShort();
    error VersionNotRegistered();

    // Mapping of version -> verification contract
    mapping(uint8 => address) private _verifiers;

    /**
     * @notice Sets or updates the verification contract for a given version.
     * @param version The version byte
     * @param verifier The address of the contract implementing ISigImplementation
     * @dev This function is internal and should be called using checkAccess
     */
    function _setVerifier(uint8 version, address verifier) internal {
        _verifiers[version] = verifier;
    }

    /**
     * @notice Retrieves the verifier contract for a given version.
     */
    function getVerifier(
        uint8 version
    ) external view virtual returns (address) {
        return _verifiers[version];
    }

    /**
     * @dev Extracts the version from the first byte of the key, routes the rest
     *      of the key to the appropriate verifier contract, and checks
     *      if the signature is valid.
     */
    function _verifyKeySignature(
        address operator,
        bytes memory key_,
        bytes memory signature
    ) internal view virtual override returns (bool) {
        if (key_.length <= 1) revert KeyTooShort();

        // Extract the first byte (version)
        uint8 version = uint8(key_[0]);

        // Copy the rest of the key (minus the version byte)
        bytes memory keyWithoutVersion = new bytes(key_.length - 1);
        for (uint256 i = 1; i < key_.length; i++) {
            keyWithoutVersion[i - 1] = key_[i];
        }

        // Find the verifier for this version
        address verifier = _verifiers[version];
        if (verifier == address(0)) revert VersionNotRegistered();

        // Delegate call to the verifier’s verifySignature method
        return ISigImplementation(verifier).verifySignature(operator, keyWithoutVersion, signature);
    }
}
