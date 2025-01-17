#!/bin/bash

# Load environment variables
source .env

# Script configuration
SCRIPT_PATH="script/deploy/HyveMiddleware.s.sol"
CHAIN_ID=11155111  # Sepolia

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}Deploying HyveMiddleware to Sepolia...${NC}"
echo "Network: Sepolia (${CHAIN_ID})"
echo "RPC URL: ${SEPOLIA_RPC_URL}"

# Deploy with verification
forge script ${SCRIPT_PATH} \
    --rpc-url ${SEPOLIA_RPC_URL} \
    --broadcast \
    --verify \
    --chain-id ${CHAIN_ID} \
    -vvvv

echo -e "${GREEN}Deployment complete!${NC}"