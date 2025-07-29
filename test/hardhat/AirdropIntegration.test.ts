import "hardhat"
import { ethers } from "hardhat"
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers"
import { expect } from "chai"

import { Airdrop, Airdrop__factory } from "../../typechain-types"
import Merkle from '../../script/merkle'

interface WhitelistItem {
    userWallet: string
    claimAmount: string
}

describe("Airdrop contract", () => {
    let airdrop: Airdrop
    let owner: HardhatEthersSigner
    let whitelist: WhitelistItem[]
    let merkle: Merkle<WhitelistItem>

    beforeEach(async () => {
        whitelist = generateTestWhitelist()
        airdrop = await loadAirdrop()
        owner = await getSigner()
        merkle = await makeMerkleTree(whitelist)

        await fundAirdropWithTotalAllocation(whitelist, airdrop, owner)
    })

    it("Should update merkle root", async () => {
        const root = merkle.getRoot()
        const updatedRoot = await updateMerkleRoot(airdrop, root)
        expect(updatedRoot).to.eq(root)
    })

    it("Merkle leaf at index 0 should equal to mapped allocation", async () => {
        const mapper = await buildMapperFunction()

        const index = 0
        const allocation = whitelist[index]!
        const hashedAllocation = ethers.keccak256(mapper(allocation))
        const leaf = "0x" + merkle.getTree().getLeaf(index).toString("hex")
        expect(leaf).to.eq(hashedAllocation)
    })

    it("Should locally verify whitelist", () => {
        const index = 0
        const leaf = merkle.getItem(index)
        const proof = merkle.getProof(index)
        const root = merkle.getRoot().substring(2)
        const result = merkle.getTree().verify(proof, leaf, root)
        expect(result).to.be.true
    })

    it("Should airdrop", async () => {
        await updateMerkleRoot(airdrop, merkle.getRoot())

        const index = 0
        const proof = merkle.getProof(index)
        const userWallet = whitelist[index]!.userWallet
        const expectedAmount = BigInt(whitelist[index]!.claimAmount)

        const balanceBefore = await ethers.provider.getBalance(userWallet)

        // shortcut for block confirmation
        await (await airdrop.airdrop(whitelist[index]!, proof)).wait()

        const balanceAfter = await ethers.provider.getBalance(userWallet)
        expect(balanceAfter - balanceBefore).to.eq(expectedAmount)
    })

    it("Should fail airdrop", async () => {
        await updateMerkleRoot(airdrop, merkle.getRoot())

        const index = 0
        whitelist[index]!.claimAmount += 1 // string+1 makes total sense, JS things!
        merkle = await makeMerkleTree(whitelist)
        const proof = merkle.getProof(index)

        let failed = false
        try {
            await (await airdrop.airdrop(whitelist[index]!, proof)).wait()
        } catch {
            failed = true
        }

        expect(failed).to.be.true
    })
})

async function makeMerkleTree(whitelist: WhitelistItem[]): Promise<Merkle<WhitelistItem>> {
    return new Merkle(whitelist, await buildMapperFunction(), ethers.keccak256)
}

async function getSigner(): Promise<HardhatEthersSigner> {
    const [owner] = await ethers.getSigners()
    if (!owner) throw new Error("No signers available")

    return owner
}

async function loadAirdrop(): Promise<Airdrop> {
    const owner = await getSigner()
    return new Airdrop__factory(owner).deploy(owner)
}

function generateTestWhitelist(): WhitelistItem[] {
    return Array.from({ length: 10 }, () => {
        // generate random amount between 0.1 and 10 ETH
        const randomEth = Math.random() * 9.9 + 0.1
        const claimAmount = ethers.parseEther(randomEth.toString()).toString()

        return {
            userWallet: ethers.Wallet.createRandom().address,
            claimAmount: claimAmount
        }
    })
}

async function fundAirdropWithTotalAllocation(whitelist: WhitelistItem[], airdrop: Airdrop, signer: HardhatEthersSigner) {
    const totalClaimAmount = whitelist.reduce((sum, user) => {
        return sum + BigInt(user.claimAmount)
    }, 0n)

    await signer.sendTransaction({
        to: await airdrop.getAddress(),
        value: totalClaimAmount
    })
}

async function buildMapperFunction(): Promise<(item: WhitelistItem) => string> {
    const chainId = (await ethers.provider.getNetwork()).chainId
    return (item: WhitelistItem): string => {
        return ethers.solidityPacked(
            ["address", "uint256", "uint256"],
            [item.userWallet, item.claimAmount, chainId]
        )
    }
}

async function updateMerkleRoot(airdrop: Airdrop, root: string): Promise<string> {
    const tx = await airdrop.updateMerkleRoot(root)
    await tx.wait() // wait to confirm tx after 1 block

    return await airdrop.merkleRoot()
}