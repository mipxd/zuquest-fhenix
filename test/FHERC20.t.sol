// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25 <0.9.0;

import { Test } from "forge-std/src/Test.sol";

import { ZuquestStakes, FHERC20NotAuthorized } from "../src/FHERC20.sol";
import { FheEnabled } from "../util/FheHelper.sol";
import { Permission, PermissionHelper } from "../util/PermissionHelper.sol";

import { inEuint128, euint128 } from "@fhenixprotocol/contracts/FHE.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract TokenTest is Test, FheEnabled {
    ZuquestStakes internal token;
    PermissionHelper private permitHelper;

    address public owner;
    uint256 public ownerPrivateKey;

    uint256 private testerPrivateKey;
    address private tester;

    Permission private permission;
    Permission private permissionTester;

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        // Required to mock FHE operations - do not forget to call this function
        // *****************************************************
        initializeFhe();
        // *****************************************************

        testerPrivateKey = 0xB0B;
        tester = vm.addr(testerPrivateKey);

        ownerPrivateKey = 0xA11CE;
        owner = vm.addr(ownerPrivateKey);

        vm.startPrank(owner);

        // Instantiate the contract-under-test.
        token = new ZuquestStakes("ZuQuestToken", "ZQT");
        permitHelper = new PermissionHelper(address(token));

        permission = permitHelper.generatePermission(ownerPrivateKey);
        permissionTester = permitHelper.generatePermission(testerPrivateKey);

        vm.stopPrank();
    }


    // @dev Test mintEncrypted function with authorized minter
    function testMintEncrypted() public {
        uint128 value = 50;
        vm.startPrank(tester);
        inEuint128 memory encryptedValue = encrypt128(value);
        token.mintEncrypted(tester, encryptedValue);
        string memory encryptedBalance = token.balanceOfEncrypted(tester, permissionTester);
        uint256 balance = unseal(address(token), encryptedBalance);
        assertEq(balance, uint256(value));
        vm.stopPrank();
    }

    function testStake() public {
        vm.startPrank(tester);
        uint128 value = 50;
        inEuint128 memory encryptedValue = encrypt128(value);
        token.stake(tester, "test", encryptedValue);
        uint256 balance = token.getMyBidZeroPrivacy(tester, "test");
        assertEq(balance, uint256(value));
        vm.stopPrank();
    }

}
