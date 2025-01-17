// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {OzAccessControl} from "@symbiotic-middleware/extensions/managers/access/OzAccessControl.sol";
import {SharedVaults} from "@symbiotic-middleware/extensions/SharedVaults.sol";
import {SelfRegisterOperators} from "@symbiotic-middleware/extensions/operators/SelfRegisterOperators.sol";

import {OzAccessControl} from "@symbiotic-middleware/extensions/managers/access/OzAccessControl.sol";
import {EpochCapture} from "@symbiotic-middleware/extensions/managers/capture-timestamps/EpochCapture.sol";
import {EqualStakePower} from "@symbiotic-middleware/extensions/managers/stake-powers/EqualStakePower.sol";
import {KeyManagerBytes} from "@symbiotic-middleware/extensions/managers/keys/KeyManagerBytes.sol";

import {SigRouter} from "./extensions/SigRouter.sol";

contract HyveMiddleware is
    SharedVaults,
    SelfRegisterOperators,
    KeyManagerBytes,
    OzAccessControl,
    SigRouter,
    EpochCapture,
    EqualStakePower
{
    bytes32 public constant VERIFIER_SETTER_ROLE = keccak256("VERIFIER_SETTER_ROLE");

    function initialize(
        address network,
        uint48 slashingWindow,
        address vaultRegistry,
        address operatorRegistry,
        address operatorNetOptIn,
        address reader,
        address owner,
        uint48 epochDuration
    ) external initializer {
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
