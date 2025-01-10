// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 * @dev Interface for an external slash distribution calculator contract.
 *      It provides the victim's amount and address based on slash event data.
 */
interface ISlashDistributionCalculator {
    function getDistributionData(
        bytes32 subnetwork,
        address operator,
        uint256 slashAmount,
        uint48 captureTimestamp
    ) external view returns (uint256 victimAmount, address victimAddr);
}
