# MerkleTree usage in Solidity and TypeScript

This is the example repository for my Medium article on [Merkle Trees](#).

### Directory structure

```
.
├── lib                         -- Solidity dependencies
│   ├── forge-std               -- Forge standard library
│   ├── murky                   -- Efficient Merkle Tree implementation
│   └── openzeppelin-contracts  -- OpenZeppelin!
├── script                      -- Additional Foundry and Hardhat scripts and utilities
├── src                         -- Solidity source, containing a single Airdrop.sol
└── test                        -- Unit tests
    ├── foundry                 -- Foundry specific tests (Solidity)
    └── hardhat                 -- Hardhat integration tests (TypeScript)
```

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
