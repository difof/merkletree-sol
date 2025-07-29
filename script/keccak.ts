import createHash from 'keccak'

function withHash(): createHash.Keccak {
    return createHash("keccak256")
}

export default function (input: string): string {
    if (input.startsWith("0x")) {
        return withHash().update(input.slice(2), "hex").digest("hex")
    }
    return withHash().update(input).digest("hex")
}