// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IBurner} from "@symbiotic/interfaces/slasher/IBurner.sol";
import {ISlasher} from "@symbiotic/interfaces/slasher/ISlasher.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Time} from "@openzeppelin/contracts/utils/types/Time.sol";

import {ISlashDistributionCalculator} from "../interfaces/ISlashDistributionCalculator.sol";

/**
 * @title RedistributingBurner
 * @notice A custom Burner that redistributes slashed stake among vault participants
 *         (except the slashed operator) and allocates a portion to a "victim" of the slash.
 *         The victim in this case is mostly the whistleblower, but could be any address.
 *
 *         This contract calls out to an external contract (slashDistributionCalculator) to discover
 *         how much of the slashed tokens should go to the victim vs. how much should be collectively
 *         redistributed among the remaining participants in the vault.
 */
contract RedistributingBurner is IBurner, Ownable {
    using SafeERC20 for IERC20;

    error InsufficientSlashBalance();
    error SlashCalculatorNotReady();

    /// @notice The Vault's collateral (token) address
    address public immutable COLLATERAL;

    // The time-based delay for updates
    uint48 public updateDelay;

    // Storage for pending updates
    struct PendingSlashCalculator {
        address value;
        uint48 timestamp;
    }

    ISlashDistributionCalculator public slashCalculator;

    PendingSlashCalculator public pendingSlashCalculator;

    event SlashDistributionCalculatorUpdateInitiated(address indexed newCalculator, uint48 validAt);
    event SlashDistributionCalculatorUpdateAccepted(address indexed newCalculator);

    event SlashedAndRedistributed(
        bytes32 indexed subnetwork,
        address indexed operator,
        uint48 captureTimestamp,
        uint256 totalAmount,
        uint256 victimAmount,
        address victim,
        address vault,
        uint256 redistributeAmount
    );

    constructor(address _collateral, address _slashDistributionCalculator) Ownable(msg.sender) {
        COLLATERAL = _collateral;
        slashCalculator = ISlashDistributionCalculator(_slashDistributionCalculator);
    }

    /**
     * @notice Propose a new slash distribution calculator, which can only be accepted
     *         after the configured delay has passed.
     * @param newCalculator address of the new slash distribution calculator
     */
    function setSlashDistributionCalculator(
        address newCalculator
    ) external onlyOwner {
        // Schedule the pending slash calculator
        pendingSlashCalculator.value = newCalculator;
        pendingSlashCalculator.timestamp = uint48(block.timestamp) + updateDelay;

        emit SlashDistributionCalculatorUpdateInitiated(newCalculator, pendingSlashCalculator.timestamp);
    }

    /**
     * @notice Accept the proposed slash distribution calculator after the delay has passed.
     */
    function acceptSlashDistributionCalculator() external {
        _acceptSlashDistributionCalculator(pendingSlashCalculator);

        emit SlashDistributionCalculatorUpdateAccepted(address(slashCalculator));
    }

    /**
     * @inheritdoc IBurner
     * @dev This function gets called by the Slasher of a vault.
     */
    function onSlash(bytes32 subnetwork, address operator, uint256 amount, uint48 captureTimestamp) external override {
        address vault = ISlasher(msg.sender).vault();

        // 1. Receive slash calculation info from the external contract
        (uint256 victimAmount, address victimAddr) =
            _getSlashDistributionData(subnetwork, operator, amount, captureTimestamp);

        // 2. Safety check: We should have the full slash amount in this contract now.
        uint256 currentBalance = IERC20(COLLATERAL).balanceOf(address(this));
        if (currentBalance < amount) {
            revert InsufficientSlashBalance();
        }
        // 3. Send the victim portion to the victim address (if specified and non-zero)
        uint256 redistributeAmount = amount;
        if (victimAddr != address(0) && victimAmount > 0 && victimAmount <= amount) {
            IERC20(COLLATERAL).safeTransfer(victimAddr, victimAmount);
            redistributeAmount = amount - victimAmount;
        }

        // 4. Redistribute to the vault, slashed operator is excluded because of the vault's slash
        IERC20(COLLATERAL).safeTransfer(vault, redistributeAmount);

        emit SlashedAndRedistributed(
            subnetwork, operator, captureTimestamp, amount, victimAmount, victimAddr, vault, redistributeAmount
        );
    }

    function _getSlashDistributionData(
        bytes32 subnetwork,
        address operator,
        uint256 slashAmount,
        uint48 captureTimestamp
    ) internal view returns (uint256 victimAmount, address victimAddr) {
        return slashCalculator.getDistributionData(subnetwork, operator, slashAmount, captureTimestamp);
    }

    function _acceptSlashDistributionCalculator(
        PendingSlashCalculator storage _pendingSlashCalculator
    ) internal {
        if (_pendingSlashCalculator.timestamp == 0 || _pendingSlashCalculator.timestamp > Time.timestamp()) {
            revert SlashCalculatorNotReady();
        }

        slashCalculator = ISlashDistributionCalculator(_pendingSlashCalculator.value);
        _pendingSlashCalculator.timestamp = 0;
        _pendingSlashCalculator.value = address(0);
    }
}
