import createHash from "keccak"
import MerkleTree from "merkletreejs"
import { expect } from "chai"

describe("Simple MerkleTree", () => {
    it("Should verify the input", () => {
        // Hash function
        function hash(value: string): string {
            return createHash("keccak256").update(value).digest("hex")
        }

        // Dataset
        const whitelist = [
            "0x742d35cc6b8B4C0532C15f9AD3E8b8c8bB8c9e3f", // Wallet 1
            "0x8ba1f109551bD432803012645Hac189451c4e155", // Wallet 2
            "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984", // Wallet 3
            "0x6B175474E89094C44Da98b954EedeAC495271d0F", // Wallet 4
        ]

        // Building the tree
        const leaves = whitelist.map(addr => hash(addr))
        const tree = new MerkleTree(leaves, hash)

        // This root should be stored on the verifier side
        const root = tree.getRoot().toString("hex")

        // Extracting proof for wallet 1
        const leafWallet1 = hash(whitelist[0]!)
        const proof = tree.getProof(leafWallet1)

        expect(tree.verify(proof, leafWallet1, root)).to.be.true
    })
})