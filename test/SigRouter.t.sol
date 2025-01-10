// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {SigRouter} from "../src/extensions/SigRouter.sol";
import {ISigImplementation} from "../src/interfaces/ISigImplementation.sol";

// Mock implementation of SigRouter for testing
contract TestSigRouter is SigRouter {
    function exposed_verifyKeySignature(
        address operator,
        bytes memory key,
        bytes memory signature
    ) external view returns (bool) {
        return _verifyKeySignature(operator, key, signature);
    }

    // anyone can set a verifier
    function setVerifier(uint8 version, address verifier) external {
        _setVerifier(version, verifier);
    }
}

// Mock implementation of ISigImplementation
contract MockVerifier is ISigImplementation {
    bool private returnValue;

    function setReturnValue(
        bool value
    ) external {
        returnValue = value;
    }

    function verifySignature(
        address operator,
        bytes memory key,
        bytes memory signature
    ) external view override returns (bool) {
        // Simple mock implementation that returns pre-set value
        return returnValue;
    }
}

contract SigRouterTest is Test {
    TestSigRouter public router;
    MockVerifier public mockVerifier;

    // Test constants
    uint8 constant VERSION_1 = 1;
    address constant OPERATOR = address(0x123);
    bytes constant SIGNATURE = "test_signature";

    function setUp() public {
        router = new TestSigRouter();
        mockVerifier = new MockVerifier();
    }

    function test_SetVerifier() public {
        router.setVerifier(VERSION_1, address(mockVerifier));
        assertEq(router.getVerifier(VERSION_1), address(mockVerifier));
    }

    function test_VerifyKeySignature_Success() public {
        // Setup
        router.setVerifier(VERSION_1, address(mockVerifier));
        mockVerifier.setReturnValue(true);

        // Create key with version byte
        bytes memory key = new bytes(33); // 1 byte version + 32 bytes key
        key[0] = bytes1(VERSION_1);
        for (uint256 i = 1; i < key.length; i++) {
            key[i] = bytes1(uint8(i)); // Fill rest with dummy data
        }

        bool result = router.exposed_verifyKeySignature(OPERATOR, key, SIGNATURE);
        assertTrue(result);
    }

    function test_VerifyKeySignature_VersionNotRegistered() public {
        bytes memory key = new bytes(33);
        key[0] = bytes1(uint8(2)); // Unregistered version

        vm.expectRevert(SigRouter.VersionNotRegistered.selector);
        router.exposed_verifyKeySignature(OPERATOR, key, SIGNATURE);
    }

    function test_VerifyKeySignature_KeyTooShort() public {
        bytes memory key = new bytes(1); // Only version byte

        vm.expectRevert(SigRouter.KeyTooShort.selector);
        router.exposed_verifyKeySignature(OPERATOR, key, SIGNATURE);
    }

    function test_VerifyKeySignature_EmptyKey() public {
        bytes memory key = new bytes(0);

        vm.expectRevert(SigRouter.KeyTooShort.selector);
        router.exposed_verifyKeySignature(OPERATOR, key, SIGNATURE);
    }

    function test_VerifyKeySignature_FailedVerification() public {
        // Setup
        router.setVerifier(VERSION_1, address(mockVerifier));
        mockVerifier.setReturnValue(false);

        bytes memory key = new bytes(33);
        key[0] = bytes1(VERSION_1);

        bool result = router.exposed_verifyKeySignature(OPERATOR, key, SIGNATURE);
        assertFalse(result);
    }
}
