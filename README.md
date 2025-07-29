# MerkleTree usage in Solidity and TypeScript

This is the example repository for my Medium article on [Merkle Trees](#).

### Build and test docker image

```sh
docker build -t merkletree-sol .
docker run --rm -it merkletree-sol
```

### Build and test from source

Dependencies:

- [bun](https://bun.com/docs/installation)
- [foundry](https://getfoundry.sh/)

Setup libraries and modules:

```sh
foundry install
bun install
```

Run foundry tests: `forge test`

Run integration tests: `bun run hardhat test`
