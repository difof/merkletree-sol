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
error AlreadyClaimed(address userWallet);

event MerkleRootUpdated(bytes32 previous, bytes32 updated);
event Received(address sender, uint amount);
event AirdroppedEther(address receiver, uint256 amount);

// NOTE: Use a multisig wallet for maximum ownership security
contract Airdrop is Ownable, ReentrancyGuard {
    using Address for address payable;

    bytes32 public merkleRoot = 0x0;
    mapping(bytes32 => bool) public claimed;

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

        // FIXME: Add an update delay for root update, so in case of key compromise or rouge admin, the delay can give a time window for correct action: proposeMerkleRoot(root) and updateMerkleRoot()
    }

    function getLeaf(
        address _user,
        uint256 _amount
    ) public view returns (bytes32) {
        return keccak256(abi.encodePacked(_user, _amount, block.chainid));
    }

    function verifyEligibility(
        bytes32 _leaf,
        bytes32[] calldata _proof
    ) public view returns (bool) {
        return merkle.verifyProof(merkleRoot, _proof, _leaf);
    }

    function airdrop(
        Membership calldata _membership,
        bytes32[] calldata _proof
    ) external nonReentrant {
        address user = _membership.userWallet;
        uint256 amount = _membership.claimAmount;
        bytes32 leaf = getLeaf(user, amount);

        if (!verifyEligibility(leaf, _proof)) {
            revert NotEligible(user);
        }

        if (claimed[leaf]) {
            revert AlreadyClaimed(user);
        }

        claimed[leaf] = true;
        payable(user).sendValue(amount);
        emit AirdroppedEther(user, amount);
    }
}
