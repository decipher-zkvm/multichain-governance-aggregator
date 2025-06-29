#!/bin/bash

echo "=== MULTICHAIN GOVERNANCE MANUAL TEST ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Step 1: Run the comprehensive test suite${NC}"
echo "forge test --match-contract 'SimplifiedMultichainTest' -v"
echo ""

echo -e "${BLUE}Step 2: Run individual test scenarios${NC}"
echo "# Test full workflow:"
echo "forge test --match-test 'testMultichainGovernanceWorkflow' -vv"
echo ""
echo "# Test cross-chain voting:"
echo "forge test --match-test 'testCrossChainVoterParticipation' -vv"
echo ""
echo "# Test chain-specific outcomes:"
echo "forge test --match-test 'testChainSpecificOutcomes' -vv"
echo ""

echo -e "${BLUE}Step 3: Test vlayer proof generation${NC}"
echo "forge test --match-contract 'GovernanceResultProverTest' -v"
echo ""

echo -e "${BLUE}Step 4: Test aggregation functionality${NC}"
echo "forge test --match-contract 'GovernanceResultVerifierTest' -v"
echo ""

echo -e "${BLUE}Step 5: Deploy to local devnet (if running)${NC}"
echo "forge script script/TestMultichainGovernance.s.sol --broadcast --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
echo ""

echo -e "${GREEN}🎯 Quick Test Command:${NC}"
echo -e "${YELLOW}forge test --match-contract 'SimplifiedMultichainTest' --match-test 'testMultichainGovernanceWorkflow' -vv${NC}"
echo ""

echo -e "${GREEN}✨ This will show you the complete multichain governance flow with:${NC}"
echo "- Ethereum: 1000 YES, 2000 NO (FAILS locally)"
echo "- Base: 1500 YES, 0 NO (PASSES locally)"  
echo "- Optimism: 1000 YES, 0 NO (PASSES locally)"
echo "- Overall: 3500 YES, 2000 NO (PASSES globally)"
echo ""

echo -e "${GREEN}🔍 To see all available tests:${NC}"
echo "forge test --list --match-path 'test/vlayer/*'"