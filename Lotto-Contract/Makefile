#Foundry Makefile Template

install:
	# Install Foundry (forge, cast, anvil)
	curl -L https://foundry.paradigm.xyz | bash
	foundryup
	# Install forge-std library
	forge install foundry-rs/forge-std
	# Install Chainlink contracts
	forge install smartcontractkit/chainlink-brownie-contracts
	# Install Brownie (Python)
	pip install eth-brownie
	# Optionally install other useful tools
	pip install web3
	npm install -g hardhat

build:
	forge build

test:
	forge test -vv

clean:
	forge clean

fmt:
	forge fmt

lint:
	forge fmt --check

anvil:
	anvil

deploy:
	forge script script/DeployStuff.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

