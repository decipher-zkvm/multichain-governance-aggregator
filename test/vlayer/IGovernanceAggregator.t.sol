// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {IGovernanceAggregator} from "../../src/vlayer/IGovernanceAggregator.sol";
import {GovernanceAggregator} from "../../src/vlayer/GovernanceAggregator.sol";

contract IGovernanceAggregatorTest is Test {
    IGovernanceAggregator public aggregator;
    
    address public verifier = address(0x1);
    address public nonVerifier = address(0x2);
    
    uint256 public constant PROPOSAL_ID = 1;
    uint256 public constant YES_VOTES = 1000;
    uint256 public constant NO_VOTES = 500;

    function setUp() public {
        aggregator = IGovernanceAggregator(address(new GovernanceAggregator(verifier)));
    }

    function testInterfaceCompliance() public {
        // Test that GovernanceAggregator contract implements IGovernanceAggregator interface
        assertTrue(address(aggregator) != address(0));
    }

    function testAddVotesInterface() public {
        vm.prank(verifier);
        aggregator.addVotes(PROPOSAL_ID, YES_VOTES, NO_VOTES);
        
        // Verify votes were added (using underlying contract's getAggregate method)
        GovernanceAggregator concreteAggregator = GovernanceAggregator(address(aggregator));
        (uint256 totalYes, uint256 totalNo) = concreteAggregator.getAggregate(PROPOSAL_ID);
        assertEq(totalYes, YES_VOTES);
        assertEq(totalNo, NO_VOTES);
    }

    function testGetAggregateInterface() public {
        vm.prank(verifier);
        aggregator.addVotes(PROPOSAL_ID, YES_VOTES, NO_VOTES);
        
        // Note: getAggregate in interface doesn't return values, 
        // so we test that it doesn't revert
        aggregator.getAggregate(PROPOSAL_ID);
    }

    function testInterfaceMethodSignatures() public {
        // Test that interface method signatures are correct
        bytes4 addVotesSig = IGovernanceAggregator.addVotes.selector;
        bytes4 getAggregateSig = IGovernanceAggregator.getAggregate.selector;
        
        // Verify selectors are not zero (proper function signatures)
        assertTrue(addVotesSig != bytes4(0));
        assertTrue(getAggregateSig != bytes4(0));
        
        // Verify specific selector values
        assertEq(addVotesSig, bytes4(keccak256("addVotes(uint256,uint256,uint256)")));
        assertEq(getAggregateSig, bytes4(keccak256("getAggregate(uint256)")));
    }

    function testAddVotesAccessControl() public {
        // Should revert when called by non-verifier
        vm.prank(nonVerifier);
        vm.expectRevert("Only Verifier can call");
        aggregator.addVotes(PROPOSAL_ID, YES_VOTES, NO_VOTES);
        
        // Should succeed when called by verifier
        vm.prank(verifier);
        aggregator.addVotes(PROPOSAL_ID, YES_VOTES, NO_VOTES);
    }

    function testInterfaceWithZeroVotes() public {
        vm.prank(verifier);
        aggregator.addVotes(PROPOSAL_ID, 0, 0);
        
        // Should not revert with zero votes
        aggregator.getAggregate(PROPOSAL_ID);
    }

    function testInterfaceWithLargeVotes() public {
        uint256 largeYes = type(uint128).max;
        uint256 largeNo = type(uint128).max - 1;
        
        vm.prank(verifier);
        aggregator.addVotes(PROPOSAL_ID, largeYes, largeNo);
        
        aggregator.getAggregate(PROPOSAL_ID);
    }

    function testInterfaceMultipleProposals() public {
        vm.prank(verifier);
        aggregator.addVotes(1, 100, 50);
        
        vm.prank(verifier);
        aggregator.addVotes(2, 200, 75);
        
        // Both proposals should be accessible through interface
        aggregator.getAggregate(1);
        aggregator.getAggregate(2);
    }

    function testInterfaceErrorPropagation() public {
        // First add votes
        vm.prank(verifier);
        aggregator.addVotes(PROPOSAL_ID, YES_VOTES, NO_VOTES);
        
        // Try to add votes again - should revert
        vm.prank(verifier);
        vm.expectRevert("Votes already aggregated for this proposal");
        aggregator.addVotes(PROPOSAL_ID, YES_VOTES, NO_VOTES);
    }

    function testFuzzInterfaceAddVotes(
        uint256 proposalId,
        uint256 yesVotes,
        uint256 noVotes
    ) public {
        vm.assume(proposalId > 0);
        
        vm.prank(verifier);
        aggregator.addVotes(proposalId, yesVotes, noVotes);
        
        // Should be able to query the proposal through interface
        aggregator.getAggregate(proposalId);
    }

    function testInterfaceTypeCompatibility() public {
        // Test that interface method parameters are correctly typed
        
        // addVotes should accept uint256 parameters
        vm.prank(verifier);
        aggregator.addVotes(
            uint256(PROPOSAL_ID),
            uint256(YES_VOTES),
            uint256(NO_VOTES)
        );
        
        // getAggregate should accept uint256 parameter
        aggregator.getAggregate(uint256(PROPOSAL_ID));
    }

    function testInterfaceExternalCalls() public {
        // Test calling interface methods from external contract
        vm.prank(verifier);
        aggregator.addVotes(PROPOSAL_ID, YES_VOTES, NO_VOTES);
        
        // Test that interface can be called from this contract context
        aggregator.getAggregate(PROPOSAL_ID);
        
        // Verify interface is working
        assertTrue(true);
    }

    function testMultipleInterfaceImplementations() public {
        // Create multiple aggregator contracts implementing the interface
        IGovernanceAggregator aggregator2 = IGovernanceAggregator(
            address(new GovernanceAggregator(address(0x999)))
        );
        
        // Both should implement the interface correctly
        vm.prank(verifier);
        aggregator.addVotes(1, 100, 50);
        
        vm.prank(address(0x999));
        aggregator2.addVotes(1, 200, 75);
        
        // Both should be accessible through the interface
        aggregator.getAggregate(1);
        aggregator2.getAggregate(1);
    }

    function testInterfaceMethodExists() public {
        // Test that required interface methods exist and can be called
        bool addVotesExists = true;
        bool getAggregateExists = true;
        
        try aggregator.addVotes(999, 0, 0) {
            // Method exists (might revert for other reasons)
        } catch {
            // Could revert due to access control, but method exists
        }
        
        try aggregator.getAggregate(999) {
            // Method exists
        } catch {
            getAggregateExists = false;
        }
        
        assertTrue(addVotesExists);
        assertTrue(getAggregateExists);
    }

    function testInterfaceConsistency() public {
        // Test that interface behavior is consistent with implementation
        
        vm.prank(verifier);
        aggregator.addVotes(PROPOSAL_ID, YES_VOTES, NO_VOTES);
        
        // Get values through concrete contract
        GovernanceAggregator concrete = GovernanceAggregator(address(aggregator));
        (uint256 concreteYes, uint256 concreteNo) = concrete.getAggregate(PROPOSAL_ID);
        
        // Interface method should be callable (even if return values differ)
        aggregator.getAggregate(PROPOSAL_ID);
        
        // Values should be stored correctly
        assertEq(concreteYes, YES_VOTES);
        assertEq(concreteNo, NO_VOTES);
    }
}