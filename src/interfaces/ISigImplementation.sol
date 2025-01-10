// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title ISigImplementation
/// @notice Interface for signature verification implementations
/// @dev Implementations of this interface should provide signature verification logic and added to the SigRouter
interface ISigImplementation {
    /// @notice Verifies a signature against an operator's key
    /// @dev Verifies a signature given the operator, the "raw" key bytes (minus version), and the signature
    /// @param operator The address associated with the signer
    /// @param keyWithoutVersion The raw public key bytes, excluding any version information
    /// @param signature The signature to validate
    /// @return bool Returns true if the signature is valid, false otherwise
    function verifySignature(
        address operator,
        bytes memory keyWithoutVersion,
        bytes memory signature
    ) external view returns (bool);
}
