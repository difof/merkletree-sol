// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

// ensure your remappings.txt contains "murky/=lib/murky/src/"
import {CompleteMerkle} from "murky/CompleteMerkle.sol";

contract TestFuzz_MerkleVerify is Test {
    CompleteMerkle merkle;

    function setUp() public {
        merkle = new CompleteMerkle();
    }

    function testFuzz_VerifyProofHappyPath(
        bytes32[] memory data, // arbitrary input data
        uint256 leafIndex // random index within dataset
    ) public view {
        // Fuzz skip case conditions
        vm.assume(data.length > 1);
        vm.assume(leafIndex < data.length);

        bytes32 root = merkle.getRoot(data);
        bytes32[] memory proof = merkle.getProof(data, leafIndex);

        bytes32 valueToProve = data[leafIndex];
        assertTrue(merkle.verifyProof(root, proof, valueToProve));
    }
}
