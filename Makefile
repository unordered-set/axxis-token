deployment-vars:
	@echo "Checking deployment variables"
	$(if $(value RPC_URL),,$(error "RPC_URL is not set"))
	$(if $(value DEPLOYER_PRIVATE_KEY),,$(error "DEPLOYER_PRIVATE_KEY is not set"))
	$(if $(value OWNER_ADDRESS),,$(error "OWNER_ADDRESS is not set"))

test:
	@echo "Running tests"
	forge t

deploy: deployment-vars
	@echo "Deploying AXXIS contract"
	forge script \
		--private-key $(DEPLOYER_PRIVATE_KEY) \
		--rpc-url $(RPC_URL) \
		--optimize \
		--optimizer-runs 200000 \
		--broadcast \
		--verify \
		script/FullNewDeploy.sol:FullNewDeployScript


.PHONY: deploy
.PHONY: deployment-vars
.PHONY: test