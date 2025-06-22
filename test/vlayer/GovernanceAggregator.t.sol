// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {GovernanceAggregator} from "../../src/vlayer/GovernanceAggregator.sol";

contract GovernanceAggregatorTest is Test {
    GovernanceAggregator public aggregator;
    
    address public verifier = address(0x1);
    address public nonVerifier = address(0x2);
    
    uint256 public constant PROPOSAL_ID = 1;

    function setUp() public {
        aggregator = new GovernanceAggregator(verifier);
    }

    function testConstructor() public {
        assertEq(aggregator.verifier(), verifier);
    }

    function testAddVotes() public {
        vm.prank(verifier);
        aggregator.addVotes(PROPOSAL_ID, 100, 50);
        
        (uint256 totalYes, uint256 totalNo) = aggregator.getAggregate(PROPOSAL_ID);
        assertEq(totalYes, 100);
        assertEq(totalNo, 50);
    }

    function testAddVotesMultipleTimes() public {
        vm.prank(verifier);
        aggregator.addVotes(1, 100, 50);
        
        vm.prank(verifier);
        aggregator.addVotes(2, 200, 75);
        
        (uint256 totalYes1, uint256 totalNo1) = aggregator.getAggregate(1);
        (uint256 totalYes2, uint256 totalNo2) = aggregator.getAggregate(2);
        
        assertEq(totalYes1, 100);
        assertEq(totalNo1, 50);
        assertEq(totalYes2, 200);
        assertEq(totalNo2, 75);
    }

    function testAddVotesFailsIfNotVerifier() public {
        vm.prank(nonVerifier);
        vm.expectRevert("Only Verifier can call");
        aggregator.addVotes(PROPOSAL_ID, 100, 50);
    }

    function testAddVotesFailsIfAlreadyAggregated() public {
        vm.prank(verifier);
        aggregator.addVotes(PROPOSAL_ID, 100, 50);
        
        vm.prank(verifier);
        vm.expectRevert("Votes already aggregated for this proposal");
        aggregator.addVotes(PROPOSAL_ID, 50, 25);
    }

    function testGetAggregateForNonExistentProposal() public {
        (uint256 totalYes, uint256 totalNo) = aggregator.getAggregate(999);
        assertEq(totalYes, 0);
        assertEq(totalNo, 0);
    }

    function testGetAggregateAfterAddingVotes() public {
        vm.prank(verifier);
        aggregator.addVotes(PROPOSAL_ID, 500, 300);
        
        (uint256 totalYes, uint256 totalNo) = aggregator.getAggregate(PROPOSAL_ID);
        assertEq(totalYes, 500);
        assertEq(totalNo, 300);
    }

    function testOnlyVerifierModifier() public {
        // Test that modifier correctly restricts access
        vm.prank(address(0x999));
        vm.expectRevert("Only Verifier can call");
        aggregator.addVotes(PROPOSAL_ID, 1, 1);
        
        // But verifier can call
        vm.prank(verifier);
        aggregator.addVotes(PROPOSAL_ID, 1, 1);
    }

    function testZeroVotesCanBeAdded() public {
        vm.prank(verifier);
        aggregator.addVotes(PROPOSAL_ID, 0, 0);
        
        (uint256 totalYes, uint256 totalNo) = aggregator.getAggregate(PROPOSAL_ID);
        assertEq(totalYes, 0);
        assertEq(totalNo, 0);
    }

    function testLargeVoteCounts() public {
        uint256 largeYes = type(uint128).max;
        uint256 largeNo = type(uint128).max - 1;
        
        vm.prank(verifier);
        aggregator.addVotes(PROPOSAL_ID, largeYes, largeNo);
        
        (uint256 totalYes, uint256 totalNo) = aggregator.getAggregate(PROPOSAL_ID);
        assertEq(totalYes, largeYes);
        assertEq(totalNo, largeNo);
    }

    function testFuzzAddVotes(uint256 proposalId, uint256 yesVotes, uint256 noVotes) public {
        vm.assume(proposalId != 0);
        
        vm.prank(verifier);
        aggregator.addVotes(proposalId, yesVotes, noVotes);
        
        (uint256 totalYes, uint256 totalNo) = aggregator.getAggregate(proposalId);
        assertEq(totalYes, yesVotes);
        assertEq(totalNo, noVotes);
    }

    function testFuzzOnlyVerifierCanAddVotes(address caller, uint256 proposalId, uint256 yesVotes, uint256 noVotes) public {
        vm.assume(caller != verifier);
        vm.assume(proposalId != 0);
        
        vm.prank(caller);
        vm.expectRevert("Only Verifier can call");
        aggregator.addVotes(proposalId, yesVotes, noVotes);
    }

    function testMultipleProposalsIndependence() public {
        vm.prank(verifier);
        aggregator.addVotes(1, 100, 50);
        
        vm.prank(verifier);
        aggregator.addVotes(2, 200, 75);
        
        vm.prank(verifier);
        aggregator.addVotes(3, 300, 100);
        
        (uint256 yes1, uint256 no1) = aggregator.getAggregate(1);
        (uint256 yes2, uint256 no2) = aggregator.getAggregate(2);
        (uint256 yes3, uint256 no3) = aggregator.getAggregate(3);
        
        assertEq(yes1, 100);
        assertEq(no1, 50);
        assertEq(yes2, 200);
        assertEq(no2, 75);
        assertEq(yes3, 300);
        assertEq(no3, 100);
    }
}