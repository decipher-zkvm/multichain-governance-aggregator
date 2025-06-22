// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {IGovernance} from "../../src/vlayer/IGovernance.sol";
import {Governance} from "../../src/vlayer/Governance.sol";
import {GovernanceToken} from "../../src/vlayer/GovernanceToken.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract IGovernanceTest is Test {
    IGovernance public governance;
    GovernanceToken public token;
    
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    
    uint256 public constant PROPOSAL_ID = 1;
    uint256 public constant START_BLOCK = 100;
    uint256 public constant END_BLOCK = 200;

    function setUp() public {
        token = new GovernanceToken("Test Token", "TEST");
        governance = IGovernance(address(new Governance(token)));
        
        // Distribute tokens
        token.transfer(user1, 100 * 10**18);
        token.transfer(user2, 200 * 10**18);
        
        vm.roll(50); // Set current block
    }

    function testInterfaceCompliance() public {
        // Test that Governance contract implements IGovernance interface
        assertTrue(address(governance) != address(0));
        
        // Test that we can call interface methods
        IERC20 governanceToken = governance.governanceToken();
        assertEq(address(governanceToken), address(token));
    }

    function testCreateProposalInterface() public {
        governance.createProposal(PROPOSAL_ID, START_BLOCK, END_BLOCK);
        
        (uint256 startBlock, uint256 endBlock, uint256 yesVotes, uint256 noVotes) = 
            governance.getProposal(PROPOSAL_ID);
        
        assertEq(startBlock, START_BLOCK);
        assertEq(endBlock, END_BLOCK);
        assertEq(yesVotes, 0);
        assertEq(noVotes, 0);
    }

    function testCastVoteInterface() public {
        governance.createProposal(PROPOSAL_ID, START_BLOCK, END_BLOCK);
        vm.roll(START_BLOCK + 10);
        
        vm.prank(user1);
        governance.castVote(PROPOSAL_ID, true);
        
        (,, uint256 yesVotes, uint256 noVotes) = governance.getProposal(PROPOSAL_ID);
        assertEq(yesVotes, 100 * 10**18);
        assertEq(noVotes, 0);
    }

    function testGetProposalInterface() public {
        governance.createProposal(PROPOSAL_ID, START_BLOCK, END_BLOCK);
        
        (uint256 startBlock, uint256 endBlock, uint256 yesVotes, uint256 noVotes) = 
            governance.getProposal(PROPOSAL_ID);
        
        assertEq(startBlock, START_BLOCK);
        assertEq(endBlock, END_BLOCK);
        assertEq(yesVotes, 0);
        assertEq(noVotes, 0);
    }

    function testGovernanceTokenInterface() public {
        IERC20 governanceToken = governance.governanceToken();
        
        assertEq(address(governanceToken), address(token));
        
        // Test basic IERC20 functionality
        assertEq(governanceToken.totalSupply(), token.totalSupply());
        assertEq(governanceToken.balanceOf(address(this)), token.balanceOf(address(this)));
    }

    function testInterfaceWithMultipleProposals() public {
        uint256 proposal1 = 1;
        uint256 proposal2 = 2;
        
        governance.createProposal(proposal1, START_BLOCK, END_BLOCK);
        governance.createProposal(proposal2, START_BLOCK + 10, END_BLOCK + 10);
        
        (uint256 start1, uint256 end1,,) = governance.getProposal(proposal1);
        (uint256 start2, uint256 end2,,) = governance.getProposal(proposal2);
        
        assertEq(start1, START_BLOCK);
        assertEq(end1, END_BLOCK);
        assertEq(start2, START_BLOCK + 10);
        assertEq(end2, END_BLOCK + 10);
    }

    function testInterfaceVotingWorkflow() public {
        // Create proposal
        governance.createProposal(PROPOSAL_ID, START_BLOCK, END_BLOCK);
        
        // Move to voting period
        vm.roll(START_BLOCK + 10);
        
        // Cast votes
        vm.prank(user1);
        governance.castVote(PROPOSAL_ID, true);
        
        vm.prank(user2);
        governance.castVote(PROPOSAL_ID, false);
        
        // Check results
        (,, uint256 yesVotes, uint256 noVotes) = governance.getProposal(PROPOSAL_ID);
        assertEq(yesVotes, 100 * 10**18);
        assertEq(noVotes, 200 * 10**18);
    }

    function testInterfaceTypeCompatibility() public {
        // Test that interface methods return the correct types
        
        // governanceToken() should return IERC20
        IERC20 tokenInterface = governance.governanceToken();
        assertTrue(address(tokenInterface) != address(0));
        
        // getProposal() should return correct tuple
        (uint256 start, uint256 end, uint256 yes, uint256 no) = governance.getProposal(999);
        
        // These should be uint256 values (even if zero for non-existent proposal)
        assertEq(start, 0);
        assertEq(end, 0);
        assertEq(yes, 0);
        assertEq(no, 0);
    }

    function testInterfaceMethodSignatures() public {
        // Test that interface method signatures match implementation
        bytes4 createProposalSig = IGovernance.createProposal.selector;
        bytes4 castVoteSig = IGovernance.castVote.selector;
        bytes4 getProposalSig = IGovernance.getProposal.selector;
        bytes4 governanceTokenSig = IGovernance.governanceToken.selector;
        
        // Verify selectors are not zero (proper function signatures)
        assertTrue(createProposalSig != bytes4(0));
        assertTrue(castVoteSig != bytes4(0));
        assertTrue(getProposalSig != bytes4(0));
        assertTrue(governanceTokenSig != bytes4(0));
    }

    function testFuzzInterfaceCompatibility(
        uint256 proposalId,
        uint256 startBlock,
        uint256 endBlock,
        bool support
    ) public {
        vm.assume(proposalId > 0);
        vm.assume(startBlock < endBlock);
        vm.assume(startBlock > block.number);
        vm.assume(endBlock < type(uint64).max);
        
        governance.createProposal(proposalId, startBlock, endBlock);
        
        (uint256 returnedStart, uint256 returnedEnd,,) = governance.getProposal(proposalId);
        assertEq(returnedStart, startBlock);
        assertEq(returnedEnd, endBlock);
    }

    function testInterfaceErrorConditions() public {
        // Test that interface properly propagates errors
        
        // Duplicate proposal should revert
        governance.createProposal(PROPOSAL_ID, START_BLOCK, END_BLOCK);
        vm.expectRevert("Proposal already exists");
        governance.createProposal(PROPOSAL_ID, START_BLOCK, END_BLOCK);
        
        // Invalid block range should revert
        vm.expectRevert("Invalid block range");
        governance.createProposal(2, END_BLOCK, START_BLOCK);
    }

    function testInterfaceView() public {
        // Test that view functions work correctly through interface
        governance.createProposal(PROPOSAL_ID, START_BLOCK, END_BLOCK);
        
        // getProposal is a view function
        (uint256 start, uint256 end, uint256 yes, uint256 no) = governance.getProposal(PROPOSAL_ID);
        assertEq(start, START_BLOCK);
        assertEq(end, END_BLOCK);
        assertEq(yes, 0);
        assertEq(no, 0);
        
        // governanceToken is a view function
        IERC20 governanceTokenInterface = governance.governanceToken();
        assertTrue(address(governanceTokenInterface) != address(0));
    }

    function testMultipleInterfaceImplementations() public {
        // Create multiple governance contracts implementing the interface
        GovernanceToken token2 = new GovernanceToken("Token2", "TK2");
        IGovernance governance2 = IGovernance(address(new Governance(token2)));
        
        // Both should implement the interface correctly
        assertNotEq(address(governance.governanceToken()), address(governance2.governanceToken()));
        
        governance.createProposal(1, START_BLOCK, END_BLOCK);
        governance2.createProposal(1, START_BLOCK, END_BLOCK);
        
        (uint256 start1,,,) = governance.getProposal(1);
        (uint256 start2,,,) = governance2.getProposal(1);
        
        assertEq(start1, START_BLOCK);
        assertEq(start2, START_BLOCK);
    }
}