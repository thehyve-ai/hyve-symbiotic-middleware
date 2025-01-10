pragma solidity ^0.8.25;

/**
 * @title Slash Strategy Interface
 * @notice Defines the data structure and functions for slash verification.
 */
interface ISlashStrategy {
    /**
     * @notice Holds parameters required for slashing.
     * @param captureTimestamp The timestamp at which the slash conditions were captured.
     * @param operator The address of the operator being slashed.
     * @param totalPower The total stake power across all vaults and subnetworks for this operator.
     * @param vaults The array of vault addresses that store stakes for this operator.
     * @param subnetworks The list of subnetworks (represented by 160-bit identifiers) used for slashing.
     */
    struct SlashParams {
        uint48 captureTimestamp;
        address operator;
        uint256 totalPower;
        address[] vaults;
        uint160[] subnetworks;
    }

    /**
     * @notice Verifies that a slash request for a given operator, amount, and data is valid.
     * @param operator The operator to be slashed.
     * @param amount The amount to slash.
     * @param data Arbitrary slash data used by the strategy (e.g., signature, proof).
     * @return A SlashParams structure containing all necessary information to proceed with slashing.
     */
    function verifySlash(
        address operator,
        uint256 amount,
        bytes calldata data
    ) external view returns (SlashParams memory);
}
