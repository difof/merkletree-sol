// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";
import {Address} from "openzeppelin/contracts/utils/Address.sol";
import {ReentrancyGuard} from "openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Merkle} from "murky/Merkle.sol";

struct Membership {
    address userWallet;
    uint256 claimAmount;
}

error NotEligible(address userWallet);

event MerkleRootUpdated(bytes32 previous, bytes32 updated);
event Received(address sender, uint amount);
event AirdroppedEther(address receiver, uint256 amount);

contract Airdrop is Ownable, ReentrancyGuard {
    using Address for address payable;

    bytes32 public merkleRoot = 0x0;

    Merkle public merkle;

    constructor(address _admin) Ownable(_admin) {
        merkle = new Merkle();
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable {
        emit Received(msg.sender, msg.value);
    }

    function updateMerkleRoot(bytes32 _root) external onlyOwner {
        emit MerkleRootUpdated(merkleRoot, _root);
        merkleRoot = _root;
    }

    function verifyEligibility(
        address _user,
        uint256 _amount,
        bytes32[] calldata _proof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(
            abi.encodePacked(_user, _amount, block.chainid)
        );

        return merkle.verifyProof(merkleRoot, _proof, leaf);
    }

    function airdrop(
        Membership calldata _membership,
        bytes32[] calldata proof
    ) external nonReentrant {
        address user = _membership.userWallet;
        uint256 amount = _membership.claimAmount;

        if (!verifyEligibility(user, amount, proof)) {
            revert NotEligible(user);
        }

        payable(user).sendValue(amount);
        emit AirdroppedEther(user, amount);
    }
}
