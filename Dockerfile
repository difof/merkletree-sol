from ubuntu:22.04

run apt update

run apt install -y curl unzip git && rm -rf /var/lib/apt/lists/*

run curl -L https://foundry.paradigm.xyz | bash

run curl -fsSL https://bun.com/install | bash -s "bun-v1.2.19"

env PATH="/root/.foundry/bin:${PATH}"
env PATH="/root/.bun/bin:$PATH"

run foundryup --install 0.3.0

workdir /app

copy .git /app/.git
copy .gitmodules /app/.gitmodules
copy lib /app/lib
copy script /app/script
copy src /app/src
copy test /app/test
copy package.json package-lock.json bun.lock tsconfig.json /app
copy foundry.toml hardhat.config.ts remappings.txt /app

run forge install
run forge compile
run bun install
run bun run hardhat compile

cmd ["bash", "-c", "forge test -vvv && bun run hardhat test"]