import MerkleTree from "merkletreejs"

export type DataItem = object
export type HexString = string

export type MapperFunction<T extends DataItem> = (item: T) => string
export type HashFunction = (input: string) => HexString

class MerkleWrapper<T extends DataItem> {
    readonly #mapperFunction: MapperFunction<T>
    readonly #hashFunction: HashFunction
    readonly #tree: MerkleTree
    readonly #hashedData: HexString[]

    constructor(dataset: T[], mapperFunction: MapperFunction<T>, hashFunction: HashFunction) {
        this.#mapperFunction = mapperFunction
        this.#hashFunction = hashFunction
        this.#hashedData = dataset.map(this.#mapperFunction).map(this.#hashFunction)

        this.#tree = new MerkleTree(this.#hashedData, hashFunction, {
            sortPairs: true,
        })
    }

    getRoot(): HexString {
        return "0x" + this.#tree.getRoot().toString("hex")
    }

    getProof(indexOrItem: number | T): HexString[] {
        const item = this.getItem(indexOrItem)
        return this.#tree.getHexProof(item)
    }

    getTree(): MerkleTree { return this.#tree }

    getItem(indexOrItem: number | T): HexString {
        if (typeof indexOrItem === "number") {
            return this.#hashedData[indexOrItem]!
        }
        return this.#hashFunction(this.#mapperFunction(indexOrItem))
    }
}

export default MerkleWrapper
