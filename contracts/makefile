CHAIN_ID := 421611
RPC_URL := https://rinkeby.arbitrum.io/rpc
CHAIN_ID_MAINNET := 42161
RPC_URL_MAINNET ?= https://arb1.arbitrum.io/rpc

test:
	forge test -vvv --no-match-contract "(ZapInOutHelper|StrategyGamma|StrategyPendleCamelot|StrategyPendleRocket|StrategyPendleLido|StrategyVela)"

test-slow:
	forge test -vvv --match-contract "(ZapInOutHelper|StrategyGamma|StrategyPendleCamelot|StrategyPendleRocket|StrategyPendleLido|StrategyVela)"

tst:
	forge test -vvv --match-contract StrategyGMXGM

build:
	forge build

clean:
	rm -rf broadcast out cache

fmt:
	find src/*.sol src/**/*.sol | xargs -n 1 -t forge fmt

node:
	anvil --chain-id 1337 # -b 2

initcodehash:
	forge script src/scripts/UniV2InitcodeHash.s.sol:UniV2InitcodeHash

poolinfo:
	forge script src/scripts/PoolInfo.s.sol:PoolInfo \
		-vvvv --fork-url $(RPC_URL_MAINNET)

call:
	cast call --rpc-url=$(RPC_URL_MAINNET) 0x656ca10e32447fdd9502d61c6ff696b622862ab5 "expiry() returns (uint256)"
	#cast call --rpc-url=$(RPC_URL_MAINNET) 0x9D6A853Da8BF51386240Ad1ed19E13C48dF3a2A7 "exec(address) returns (bool)" "0x20dE070F1887f82fcE2bdCf5D6d9874091e6FAe9"

debug:
	forge script src/scripts/Debug.s.sol:Debug \
		-vvvv --fork-url $(RPC_URL_MAINNET)

debug-local:
	forge script src/scripts/Debug.s.sol:Debug \
		-vvvv --fork-url http://localhost:8545

deploy-local:
	forge script src/scripts/DeployLocal.s.sol:DeployLocal \
		--rpc-url http://localhost:8545  \
		--private-key ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
		--broadcast -vvvv

deploy:
	forge script src/scripts/Deploy.s.sol:Deploy \
		--rpc-url $(RPC_URL_MAINNET)  \
		--private-key $(RODEO_PRIVATE_KEY_MAINNET) \
		--broadcast --verify -vvvv --slow --with-gas-price 200000000 \
		--etherscan-api-key $(RODEO_ETHERSCAN_KEY)

deploy-staging:
	forge script src/scripts/DeployStaging.s.sol:DeployStaging \
		--rpc-url $(RPC_URL_MAINNET)  \
		--private-key $(RODEO_PRIVATE_KEY_MAINNET) \
		--broadcast --verify -vvvv \
		--etherscan-api-key $(RODEO_ETHERSCAN_KEY)

# ~/.svm/0.8.15/solc-0.8.15 --version
verify:
	forge verify-contract \
		--chain-id $(CHAIN_ID_MAINNET) --num-of-optimizations 200 \
		--compiler-version 0.8.17+commit.8df45f5f \
		--constructor-args $(shell cast abi-encode "constructor(address)" "0x8accf43Dd31DfCd4919cc7d65912A475BfA60369") \
		0x9D6A853Da8BF51386240Ad1ed19E13C48dF3a2A7 \
		src/InvestorActor.sol:InvestorActor $(RODEO_ETHERSCAN_KEY)
