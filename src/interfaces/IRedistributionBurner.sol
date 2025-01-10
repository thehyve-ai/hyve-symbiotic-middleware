pragma solidity ^0.8.25;

import {IBurner} from "@symbiotic/interfaces/slasher/IBurner.sol";

interface IRedistributionBurner is IBurner {
    struct SlashingDetails {
        uint256 slashId;
        address compReceiver;
        uint256 compDenominator;
        uint256 penaltyDenominator;
        bool isKicked;
    }
}
