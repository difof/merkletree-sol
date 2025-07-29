// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";

import "../../src/Airdrop.sol";

contract Test_Airdrop_DoubleSpend is Test {
    uint256 constant mockChainId = 1234;

    Airdrop internal artifact;
    address internal owner = address(0xA);
    address internal claimant = address(0xB);

    function setUp() public {
        vm.chainId(mockChainId);
        artifact = new Airdrop(owner);
        deal(address(artifact), 10 ether);
    }

    function test_AirdropDoubleSpendReverts() public {
        uint256 claimAmount = 1 ether;

        bytes32 leaf = keccak256(
            abi.encodePacked(claimant, claimAmount, mockChainId)
        );
        bytes32 dummyLeaf = keccak256(
            abi.encodePacked(address(0xDEADBEEF), uint256(0), mockChainId)
        );
        bytes32[] memory leaves = new bytes32[](2);
        leaves[0] = leaf;
        leaves[1] = dummyLeaf;

        bytes32 root = artifact.merkle().getRoot(leaves);

        vm.startPrank(owner);
        artifact.updateMerkleRoot(root);
        vm.stopPrank();

        bytes32[] memory proof = artifact.merkle().getProof(leaves, 0);

        Membership memory member = Membership({
            userWallet: claimant,
            claimAmount: claimAmount
        });

        // first claim succeeds.
        vm.prank(claimant);
        artifact.airdrop(member, proof);

        // second claim should revert with AlreadyClaimed.
        vm.expectRevert(
            abi.encodeWithSelector(AlreadyClaimed.selector, claimant)
        );
        vm.prank(claimant);
        artifact.airdrop(member, proof);
    }
}
