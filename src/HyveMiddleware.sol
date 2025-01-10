// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {OzAccessControl} from "@symbiotic-middleware/extensions/managers/access/OzAccessControl.sol";
import {BaseMiddleware} from "@symbiotic-middleware/middleware/BaseMiddleware.sol";
import {SharedVaults} from "@symbiotic-middleware/extensions/SharedVaults.sol";
import {SelfRegisterOperators} from "@symbiotic-middleware/extensions/operators/SelfRegisterOperators.sol";

import {ECDSASig} from "@symbiotic-middleware/extensions/managers/sigs/ECDSASig.sol";
import {OzAccessControl} from "@symbiotic-middleware/extensions/managers/access/OzAccessControl.sol";
import {EpochCapture} from "@symbiotic-middleware/extensions/managers/capture-timestamps/EpochCapture.sol";
import {EqualStakePower} from "@symbiotic-middleware/extensions/managers/stake-powers/EqualStakePower.sol";
import {KeyManagerBytes} from "@symbiotic-middleware/extensions/managers/keys/KeyManagerBytes.sol";

import {SigRouter} from "./extensions/SigRouter.sol";
import {SlashManager} from "./extensions/SlashManager.sol";

contract HyveMiddleware is
    OzAccessControl,
    SigRouter,
    SlashManager,
    SharedVaults,
    KeyManagerBytes,
    SelfRegisterOperators,
    EpochCapture,
    EqualStakePower
{
    bytes32 public constant VERIFIER_SETTER_ROLE = keccak256("VERIFIER_SETTER_ROLE");

    /**
     * @notice Constructor for initializing the SelfRegisterMiddleware contract
     * @param network The address of the network
     * @param slashingWindow The duration of the slashing window
     * @param vaultRegistry The address of the vault registry
     * @param operatorRegistry The address of the operator registry
     * @param operatorNetOptin The address of the operator network opt-in service
     * @param reader The address of the reader contract used for delegatecall
     * @param owner The address of the owner
     */
    constructor(
        address network,
        uint48 slashingWindow,
        address vaultRegistry,
        address operatorRegistry,
        address operatorNetOptin,
        address reader,
        address owner,
        uint48 epochDuration
    ) {
        initialize(
            network, slashingWindow, vaultRegistry, operatorRegistry, operatorNetOptin, reader, owner, epochDuration
        );
    }

    function initialize(
        address network,
        uint48 slashingWindow,
        address vaultRegistry,
        address operatorRegistry,
        address operatorNetOptIn,
        address reader,
        address owner,
        uint48 epochDuration
    ) internal initializer {
        __BaseMiddleware_init(network, slashingWindow, vaultRegistry, operatorRegistry, operatorNetOptIn, reader);
        __SelfRegisterOperators_init("HyveSelfRegisterMiddleware");
        __OzAccessControl_init(owner);
        __EpochCapture_init(epochDuration);

        _grantRole(VERIFIER_SETTER_ROLE, owner);
        _setSelectorRole(this.setVerifier.selector, VERIFIER_SETTER_ROLE);
    }

    function setVerifier(uint8 version, address verifier) external checkAccess {
        _setVerifier(version, verifier);
    }
}
