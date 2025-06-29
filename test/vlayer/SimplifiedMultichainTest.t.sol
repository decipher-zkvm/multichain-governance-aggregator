// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {Governance} from "../../src/vlayer/Governance.sol";
import {GovernanceToken} from "../../src/vlayer/GovernanceToken.sol";
import {GovernanceAggregator} from "../../src/vlayer/GovernanceAggregator.sol";

contract SimplifiedMultichainTest is Test {
    // Core contracts for different chains (vlayer supported)
    GovernanceToken public token;
    Governance public ethereumGov;    // Chain 1 - Ethereum
    Governance public baseGov;        // Chain 8453 - Base  
    Governance public optimismGov;    // Chain 10 - Optimism
    
    // Aggregation contract
    GovernanceAggregator public aggregator;
    
    // Test participants
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public charlie = address(0x3);
    address public mockVerifier = address(0x999);
    
    // Test constants
    uint256 public constant PROPOSAL_ID = 1;
    uint256 public VOTING_START;
    uint256 public VOTING_END;
    
    function setUp() public {
        console.log("Setting up simplified multichain governance test...");
        
        // Set timing
        VOTING_START = block.number + 10;
        VOTING_END = block.number + 100;
        
        // Deploy token
        token = new GovernanceToken("Test Governance Token", "TGT");
        
        // Deploy governance contracts for each vlayer-supported chain
        ethereumGov = new Governance(token);
        baseGov = new Governance(token);
        optimismGov = new Governance(token);
        
        // Deploy aggregator with mock verifier
        aggregator = new GovernanceAggregator(mockVerifier);
        
        // Distribute tokens
        token.transfer(alice, 1000 * 10**18);
        token.transfer(bob, 2000 * 10**18);
        token.transfer(charlie, 1500 * 10**18);
        
        console.log("Setup complete - 3 vlayer-supported chains simulated: Ethereum, Base, Optimism");
    }
    
    function testMultichainGovernanceWorkflow() public {
        console.log("=== MULTICHAIN GOVERNANCE TEST ===");
        
        // Step 1: Create proposals on all vlayer-supported chains
        console.log("Step 1: Creating proposals across all vlayer-supported chains...");
        ethereumGov.createProposal(PROPOSAL_ID, VOTING_START, VOTING_END);
        baseGov.createProposal(PROPOSAL_ID, VOTING_START, VOTING_END);
        optimismGov.createProposal(PROPOSAL_ID, VOTING_START, VOTING_END);
        console.log("+ Proposals created on Ethereum, Base, and Optimism");
        
        // Step 2: Advance to voting period
        vm.roll(VOTING_START + 1);
        console.log("Step 2: Advanced to voting period");
        
        // Step 3: Cast votes across different chains
        console.log("Step 3: Casting votes across chains...");
        
        // Ethereum: Mixed voting
        vm.startPrank(alice);
        ethereumGov.castVote(PROPOSAL_ID, true);  // 1000 YES
        vm.stopPrank();
        
        vm.startPrank(bob);
        ethereumGov.castVote(PROPOSAL_ID, false); // 2000 NO
        vm.stopPrank();
        
        // Base: Strong YES support
        vm.startPrank(charlie);
        baseGov.castVote(PROPOSAL_ID, true);   // 1500 YES
        vm.stopPrank();
        
        // Optimism: Alice also votes here (cross-chain user)
        vm.startPrank(alice);
        optimismGov.castVote(PROPOSAL_ID, true);  // 1000 YES
        vm.stopPrank();
        
        console.log("+ Votes cast:");
        console.log("  Ethereum: 1000 YES, 2000 NO");
        console.log("  Base:     1500 YES, 0 NO");
        console.log("  Optimism: 1000 YES, 0 NO");
        
        // Step 4: End voting period
        vm.roll(VOTING_END + 1);
        console.log("Step 4: Voting period ended");
        
        // Step 5: Verify individual chain results
        console.log("Step 5: Verifying individual chain results...");
        
        (, , uint256 ethYes, uint256 ethNo) = ethereumGov.getProposal(PROPOSAL_ID);
        (, , uint256 baseYes, uint256 baseNo) = baseGov.getProposal(PROPOSAL_ID);
        (, , uint256 opYes, uint256 opNo) = optimismGov.getProposal(PROPOSAL_ID);
        
        assertEq(ethYes, 1000 * 10**18, "Ethereum YES votes incorrect");
        assertEq(ethNo, 2000 * 10**18, "Ethereum NO votes incorrect");
        assertEq(baseYes, 1500 * 10**18, "Base YES votes incorrect");
        assertEq(baseNo, 0, "Base NO votes incorrect");
        assertEq(opYes, 1000 * 10**18, "Optimism YES votes incorrect");
        assertEq(opNo, 0, "Optimism NO votes incorrect");
        
        console.log("+ Individual chain results verified");
        
        // Step 6: Calculate and verify aggregated results
        console.log("Step 6: Calculating multichain aggregation...");
        
        uint256 totalYes = ethYes + baseYes + opYes;
        uint256 totalNo = ethNo + baseNo + opNo;
        
        console.log("+ Aggregated results:");
        console.logString("  Total YES votes: ");
        console.logUint(totalYes / 10**18);
        console.logString(" tokens");
        console.logString("  Total NO votes:  ");
        console.logUint(totalNo / 10**18);
        console.logString(" tokens");
        
        // Verify aggregation
        assertEq(totalYes, 3500 * 10**18, "Total YES votes incorrect");
        assertEq(totalNo, 2000 * 10**18, "Total NO votes incorrect");
        assertTrue(totalYes > totalNo, "Proposal should pass overall");
        
        // Step 7: Simulate aggregator functionality
        vm.startPrank(mockVerifier);
        aggregator.addVotes(PROPOSAL_ID, totalYes, totalNo);
        vm.stopPrank();
        
        (uint256 aggYes, uint256 aggNo) = aggregator.getAggregate(PROPOSAL_ID);
        assertEq(aggYes, totalYes, "Aggregator YES votes incorrect");
        assertEq(aggNo, totalNo, "Aggregator NO votes incorrect");
        
        console.log("+ Votes successfully aggregated in aggregator contract");
        
        // Final result
        console.log("=== FINAL RESULT ===");
        console.log("Proposal PASSED across all vlayer-supported chains!");
        console.log("Individual chain outcomes:");
        console.log("  Ethereum: FAILED (1000 YES vs 2000 NO)");
        console.log("  Base:     PASSED (1500 YES vs 0 NO)");
        console.log("  Optimism: PASSED (1000 YES vs 0 NO)");
        console.log("Multichain outcome: PASSED (3500 YES vs 2000 NO)");
        
        console.log("SUCCESS: MULTICHAIN GOVERNANCE TEST COMPLETED SUCCESSFULLY!");
    }
    
    function testCrossChainVoterParticipation() public {
        console.log("=== CROSS-CHAIN VOTER PARTICIPATION TEST ===");
        
        // Create proposals
        ethereumGov.createProposal(PROPOSAL_ID, VOTING_START, VOTING_END);
        baseGov.createProposal(PROPOSAL_ID, VOTING_START, VOTING_END);
        optimismGov.createProposal(PROPOSAL_ID, VOTING_START, VOTING_END);
        
        vm.roll(VOTING_START + 1);
        
        // Alice votes on multiple chains (she has tokens on each)
        vm.startPrank(alice);
        ethereumGov.castVote(PROPOSAL_ID, true);
        baseGov.castVote(PROPOSAL_ID, true);
        optimismGov.castVote(PROPOSAL_ID, true);
        vm.stopPrank();
        
        vm.roll(VOTING_END + 1);
        
        // Verify Alice's votes are recorded on each chain
        (, , uint256 ethYes,) = ethereumGov.getProposal(PROPOSAL_ID);
        (, , uint256 baseYes,) = baseGov.getProposal(PROPOSAL_ID);
        (, , uint256 opYes,) = optimismGov.getProposal(PROPOSAL_ID);
        
        assertEq(ethYes, 1000 * 10**18, "Alice's Ethereum vote not recorded");
        assertEq(baseYes, 1000 * 10**18, "Alice's Base vote not recorded");
        assertEq(opYes, 1000 * 10**18, "Alice's Optimism vote not recorded");
        
        console.log("+ Cross-chain voter participation verified");
        console.log("Alice's voting power utilized across 3 chains: 3000 total votes");
    }
    
    function testChainSpecificOutcomes() public {
        console.log("=== CHAIN-SPECIFIC OUTCOMES TEST ===");
        
        uint256 proposalId2 = 2;
        ethereumGov.createProposal(proposalId2, VOTING_START, VOTING_END);
        baseGov.createProposal(proposalId2, VOTING_START, VOTING_END);
        optimismGov.createProposal(proposalId2, VOTING_START, VOTING_END);
        
        vm.roll(VOTING_START + 1);
        
        // Create scenario where different chains have different outcomes
        
        // Ethereum: Strong NO
        vm.startPrank(bob);
        ethereumGov.castVote(proposalId2, false); // 2000 NO
        vm.stopPrank();
        
        // Base: Moderate YES
        vm.startPrank(charlie);
        baseGov.castVote(proposalId2, true); // 1500 YES
        vm.stopPrank();
        
        // Optimism: Strong YES
        vm.startPrank(alice);
        optimismGov.castVote(proposalId2, true); // 1000 YES
        vm.stopPrank();
        
        vm.roll(VOTING_END + 1);
        
        // Check individual outcomes
        (, , uint256 ethYes, uint256 ethNo) = ethereumGov.getProposal(proposalId2);
        (, , uint256 baseYes, uint256 baseNo) = baseGov.getProposal(proposalId2);
        (, , uint256 opYes, uint256 opNo) = optimismGov.getProposal(proposalId2);
        
        // Individual chain outcomes
        bool ethPassed = ethYes > ethNo;
        bool basePassed = baseYes > baseNo;
        bool opPassed = opYes > opNo;
        
        assertFalse(ethPassed, "Ethereum should fail");
        assertTrue(basePassed, "Base should pass");
        assertTrue(opPassed, "Optimism should pass");
        
        // Overall outcome
        uint256 totalYes = ethYes + baseYes + opYes;
        uint256 totalNo = ethNo + baseNo + opNo;
        bool overallPassed = totalYes > totalNo;
        
        assertTrue(overallPassed, "Overall should pass (2500 YES vs 2000 NO)");
        
        console.log("+ Chain-specific outcomes verified:");
        console.log("  Ethereum: FAILED, Base: PASSED, Optimism: PASSED");
        console.log("  Overall: PASSED");
    }
}