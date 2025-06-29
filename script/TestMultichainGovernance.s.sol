// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script, console} from "forge-std/Script.sol";
import {Governance} from "../src/vlayer/Governance.sol";
import {GovernanceToken} from "../src/vlayer/GovernanceToken.sol";
import {GovernanceAggregator} from "../src/vlayer/GovernanceAggregator.sol";
import {GovernanceResultVerifier} from "../src/vlayer/GovernanceResultVerifier.sol";

contract TestMultichainGovernanceScript is Script {
    // Contracts
    GovernanceToken public token;
    Governance public ethereumGov;
    Governance public baseGov;
    Governance public optimismGov;
    GovernanceAggregator public aggregator;
    
    // Test accounts
    address public alice = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address public bob = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    address public charlie = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
    address public mockVerifier = address(0x999);
    
    // Proposal settings
    uint256 public constant PROPOSAL_ID = 1;
    uint256 public votingStart;
    uint256 public votingEnd;
    
    function run() public {
        vm.startBroadcast();
        
        console.log("=== MULTICHAIN GOVERNANCE DEPLOYMENT & TESTING ===");
        
        // Set voting periods
        votingStart = block.number + 10;
        votingEnd = block.number + 100;
        
        // Deploy contracts
        deployContracts();
        
        // Distribute tokens
        distributeTokens();
        
        // Create proposals on all chains
        createProposals();
        
        // Simulate time passing to voting period
        console.log("To test voting, you would now:");
        console.log("1. Wait for block", votingStart, "to start voting");
        console.log("2. Cast votes on different chains");
        console.log("3. Wait for block", votingEnd, "to end voting");
        console.log("4. Aggregate results using vlayer proofs");
        
        // Print contract addresses for manual testing
        printContractInfo();
        
        vm.stopBroadcast();
    }
    
    function deployContracts() internal {
        console.log("Deploying multichain governance contracts...");
        
        // Deploy token
        token = new GovernanceToken("Multichain Governance Token", "MGT");
        console.log("GovernanceToken deployed at:", address(token));
        
        // Deploy governance contracts for each vlayer-supported chain
        ethereumGov = new Governance(token);
        baseGov = new Governance(token);
        optimismGov = new Governance(token);
        
        console.log("Ethereum Governance deployed at:", address(ethereumGov));
        console.log("Base Governance deployed at:", address(baseGov));
        console.log("Optimism Governance deployed at:", address(optimismGov));
        
        // Deploy aggregator
        aggregator = new GovernanceAggregator(mockVerifier);
        console.log("GovernanceAggregator deployed at:", address(aggregator));
    }
    
    function distributeTokens() internal {
        console.log("Distributing governance tokens...");
        
        // Give tokens to test accounts
        token.transfer(alice, 1000 * 10**18);
        token.transfer(bob, 2000 * 10**18);
        token.transfer(charlie, 1500 * 10**18);
        
        console.log("Tokens distributed:");
        console.log("- Alice:", token.balanceOf(alice) / 10**18, "MGT");
        console.log("- Bob:", token.balanceOf(bob) / 10**18, "MGT");
        console.log("- Charlie:", token.balanceOf(charlie) / 10**18, "MGT");
    }
    
    function createProposals() internal {
        console.log("Creating proposals on all vlayer-supported chains...");
        
        ethereumGov.createProposal(PROPOSAL_ID, votingStart, votingEnd);
        baseGov.createProposal(PROPOSAL_ID, votingStart, votingEnd);
        optimismGov.createProposal(PROPOSAL_ID, votingStart, votingEnd);
        
        console.log("Proposal", PROPOSAL_ID, "created on all chains");
        console.log("Voting starts at block:", votingStart);
        console.log("Voting ends at block:", votingEnd);
        console.log("Current block:", block.number);
    }
    
    function printContractInfo() internal view {
        console.log("\n=== CONTRACT ADDRESSES FOR MANUAL TESTING ===");
        console.log("GovernanceToken:", address(token));
        console.log("Ethereum Governance:", address(ethereumGov));
        console.log("Base Governance:", address(baseGov));
        console.log("Optimism Governance:", address(optimismGov));
        console.log("Aggregator:", address(aggregator));
        
        console.log("\n=== TEST ACCOUNTS ===");
        console.log("Alice:", alice);
        console.log("Bob:", bob);
        console.log("Charlie:", charlie);
        
        console.log("\n=== MANUAL TESTING COMMANDS ===");
        console.log("# Check proposal status:");
        console.logString("cast call");
        console.logAddress(address(ethereumGov));
        console.logString("getProposal(uint256)");
        console.logUint(PROPOSAL_ID);
        
        console.log("\n# Cast a vote (when voting is active):");
        console.logString("cast send");
        console.logAddress(address(ethereumGov));
        console.logString("castVote(uint256,bool)");
        console.logUint(PROPOSAL_ID);
        console.logString("true --from");
        console.logAddress(alice);
        
        console.log("\n# Check vote results after voting:");
        console.logString("cast call");
        console.logAddress(address(ethereumGov));
        console.logString("getProposal(uint256)");
        console.logUint(PROPOSAL_ID);
    }
}