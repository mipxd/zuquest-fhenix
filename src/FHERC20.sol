// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { FHERC20 } from "@fhenixprotocol/contracts/experimental/token/FHERC20/FHERC20.sol";
import { inEuint128, euint128, FHE } from "@fhenixprotocol/contracts/FHE.sol";
import { inEuint32, euint32 } from "@fhenixprotocol/contracts/FHE.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

error FHERC20NotAuthorized();


contract ZuquestStakes is FHERC20 {
    mapping (string => euint128) public eventVotes;
    mapping (address => mapping(string => euint128)) public userVotes;
    uint256 public deadline;

    constructor(string memory name, string memory symbol) FHERC20(name, symbol) {
        deadline = block.timestamp + 7 days;
    }

    function mintEncrypted(address recipient, inEuint128 memory amount) public {
        _mintEncrypted(recipient, amount);
    }

    function getMyBidZeroPrivacy(address account, string memory eventName) external view returns (uint256) {
        return FHE.decrypt(userVotes[account][eventName]);
    }

    function stake(address _address, string memory eventName, inEuint128 memory amount) external {
        userVotes[_address][eventName] = FHE.asEuint128(amount);
        eventVotes[eventName] = FHE.add(eventVotes[eventName], FHE.asEuint128(amount));
    }

    function getInterest(string memory eventName) external view returns (uint256) {
        // If deadline has passed, anyone can decrypt interest
        require(block.timestamp > deadline, "Deadline has not passed");
        return FHE.decrypt(eventVotes[eventName]);
    }

    // Want to confirm we're able to call functions before trying to handle encrypted data
    function mintEncryptedFake(address recipient, uint256 amount) external {}

    function stakeFake(address _address, string memory eventName, uint256 amount) external {}

}
