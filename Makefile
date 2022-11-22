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
	forge create Exchange --constructor-args ${LOCAL_FEE_ACCOUNT} ${LOCAL_FEE_AMOUNT} src/Exchange.sol --private-key ${LOCAL_PRIVATE_KEY} --rpc-url http://localhost:8545

deploy-test :;
	forge create Exchange --constructor-args ${GORLI_FEE_ACCOUNT} ${GORLI_FEE_AMOUNT} src/Exchange.sol --private-key ${GORLI_PRIVATE_KEY} --rpc-url ${GORLI_RPC}

deploy-main :;
	forge script script/Exchange.s.sol:ExchangeScript --rpc-url ${MAINNET_RPC} --private-key ${MAINNET_KEY} --broadcast
