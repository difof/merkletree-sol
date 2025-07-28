// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";

import "../../src/Airdrop.sol";

contract TestFuzz_Airdrop is Test {
    uint256 constant mockChainId = 1234;

    function setUp() public {
        vm.chainId(mockChainId);
    }

    function testFuzz_AirdropHappyPath(
        Membership[] memory data,
        uint256 leafIndex,
        address owner
    ) public {
        vm.assume(owner != address(0x0));
        vm.assume(data.length > 1);
        vm.assume(leafIndex < data.length);
        vm.assume(data[leafIndex].userWallet != address(0x0));
        // exclude EVM precompile addresses (0x1 – 0x9)
        vm.assume(uint160(data[leafIndex].userWallet) > 9);

        Airdrop artifact = _newAirdrop(owner);

        bytes32[] memory hashedData = _hashData(data);
        _updateRoot(artifact, hashedData);

        bytes32[] memory proof = artifact.merkle().getProof(
            hashedData,
            leafIndex
        );
        Membership memory memberToClaim = data[leafIndex];

        vm.expectEmit(address(artifact));
        emit AirdroppedEther(
            memberToClaim.userWallet,
            memberToClaim.claimAmount
        );
        {
            artifact.airdrop(memberToClaim, proof);
        }

        assertTrue(
            memberToClaim.userWallet.balance == memberToClaim.claimAmount
        );
    }

    function _newAirdrop(address owner) internal returns (Airdrop artifact) {
        artifact = new Airdrop(owner);
        unchecked {
            deal(address(artifact), uint256(0) - 1);
        }
    }

    function _hashData(
        Membership[] memory data
    ) internal pure returns (bytes32[] memory buffer) {
        buffer = new bytes32[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            buffer[i] = keccak256(
                abi.encodePacked(
                    data[i].userWallet,
                    data[i].claimAmount,
                    mockChainId
                )
            );
        }
    }

    function _updateRoot(
        Airdrop artifact,
        bytes32[] memory hashedData
    ) internal {
        bytes32 root = artifact.merkle().getRoot(hashedData);

        vm.startPrank(artifact.owner());
        vm.expectEmit(address(artifact));
        emit MerkleRootUpdated(bytes32(0x0), root);
        {
            artifact.updateMerkleRoot(root);
        }
        vm.stopPrank();
    }
}
