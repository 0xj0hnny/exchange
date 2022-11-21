-include .env

#Clean the repo
clean :; forge clean

# Install the Modules
install-oz :;
	forge install OpenZeppelin/openzeppelin-contracts --no-commit

# Builds
build :; forge clean && forge build --optimize --optimize-runs 1000000

#Deploy
deploy-local :;
	forge script script/Counter.s.sol:CounterScript --fork-url http://localhost:8545 --private-key ${LOCAL_PRIVATE_KEY} --broadcast

deploy-test :;
	forge script script/Counter.s.sol:CounterScript --rpc-url ${GORLI_RPC} --private-key ${GORLI_PRIVATE_KEY} --broadcast

deploy-main :;
	forge script script/Counter.s.sol:CounterScript --rpc-url ${MAINNET_RPC} --private-key ${MAINNET_KEY} --broadcast
