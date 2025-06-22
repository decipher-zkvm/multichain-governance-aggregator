// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {Governance} from "../../src/vlayer/Governance.sol";
import {GovernanceToken} from "../../src/vlayer/GovernanceToken.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract GovernanceTest is Test {
    Governance public governance;
    GovernanceToken public token;
    
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public user3 = address(0x3);
    
    uint256 public constant PROPOSAL_ID = 1;
    uint256 public constant START_BLOCK = 100;
    uint256 public constant END_BLOCK = 200;
    
    event CastVote(address indexed voter, uint256 indexed proposalId, bool support, uint256 weight);

    function setUp() public {
        token = new GovernanceToken("Governance Token", "GOV");
        governance = new Governance(token);
        
        // Distribute tokens
        token.transfer(user1, 100 * 10**18);
        token.transfer(user2, 200 * 10**18);
        token.transfer(user3, 50 * 10**18);
        
        vm.roll(50); // Set current block
    }

    function testConstructor() public {
        assertEq(address(governance.governanceToken()), address(token));
    }

    function testCreateProposal() public {
        governance.createProposal(PROPOSAL_ID, START_BLOCK, END_BLOCK);
        
        (uint256 startBlock, uint256 endBlock, uint256 yesVotes, uint256 noVotes) = governance.getProposal(PROPOSAL_ID);
        assertEq(startBlock, START_BLOCK);
        assertEq(endBlock, END_BLOCK);
        assertEq(yesVotes, 0);
        assertEq(noVotes, 0);
    }

    function testCreateProposalFailsIfAlreadyExists() public {
        governance.createProposal(PROPOSAL_ID, START_BLOCK, END_BLOCK);
        
        vm.expectRevert("Proposal already exists");
        governance.createProposal(PROPOSAL_ID, START_BLOCK + 10, END_BLOCK + 10);
    }

    function testCreateProposalFailsWithInvalidBlockRange() public {
        vm.expectRevert("Invalid block range");
        governance.createProposal(PROPOSAL_ID, END_BLOCK, START_BLOCK);
    }

    function testCreateProposalFailsWithPastStartBlock() public {
        vm.expectRevert("Start block must be in future");
        governance.createProposal(PROPOSAL_ID, block.number - 1, END_BLOCK);
    }

    function testCreateProposalFailsWithPastEndBlock() public {
        vm.expectRevert("Invalid block range");
        governance.createProposal(PROPOSAL_ID, START_BLOCK, block.number - 1);
    }

    function testCastVoteYes() public {
        governance.createProposal(PROPOSAL_ID, START_BLOCK, END_BLOCK);
        vm.roll(START_BLOCK + 10);
        
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit CastVote(user1, PROPOSAL_ID, true, 100 * 10**18);
        governance.castVote(PROPOSAL_ID, true);
        
        (,, uint256 yesVotes, uint256 noVotes) = governance.getProposal(PROPOSAL_ID);
        assertEq(yesVotes, 100 * 10**18);
        assertEq(noVotes, 0);
    }

    function testCastVoteNo() public {
        governance.createProposal(PROPOSAL_ID, START_BLOCK, END_BLOCK);
        vm.roll(START_BLOCK + 10);
        
        vm.prank(user2);
        vm.expectEmit(true, true, false, true);
        emit CastVote(user2, PROPOSAL_ID, false, 200 * 10**18);
        governance.castVote(PROPOSAL_ID, false);
        
        (,, uint256 yesVotes, uint256 noVotes) = governance.getProposal(PROPOSAL_ID);
        assertEq(yesVotes, 0);
        assertEq(noVotes, 200 * 10**18);
    }

    function testMultipleCastVotes() public {
        governance.createProposal(PROPOSAL_ID, START_BLOCK, END_BLOCK);
        vm.roll(START_BLOCK + 10);
        
        vm.prank(user1);
        governance.castVote(PROPOSAL_ID, true);
        
        vm.prank(user2);
        governance.castVote(PROPOSAL_ID, false);
        
        vm.prank(user3);
        governance.castVote(PROPOSAL_ID, true);
        
        (,, uint256 yesVotes, uint256 noVotes) = governance.getProposal(PROPOSAL_ID);
        assertEq(yesVotes, 150 * 10**18); // user1 + user3
        assertEq(noVotes, 200 * 10**18);  // user2
    }

    function testCastVoteFailsBeforeStart() public {
        governance.createProposal(PROPOSAL_ID, START_BLOCK, END_BLOCK);
        vm.roll(START_BLOCK - 1);
        
        vm.prank(user1);
        vm.expectRevert("Voting not started");
        governance.castVote(PROPOSAL_ID, true);
    }

    function testCastVoteFailsAfterEnd() public {
        governance.createProposal(PROPOSAL_ID, START_BLOCK, END_BLOCK);
        vm.roll(END_BLOCK + 1);
        
        vm.prank(user1);
        vm.expectRevert("Voting ended");
        governance.castVote(PROPOSAL_ID, true);
    }

    function testCastVoteFailsIfAlreadyVoted() public {
        governance.createProposal(PROPOSAL_ID, START_BLOCK, END_BLOCK);
        vm.roll(START_BLOCK + 10);
        
        vm.prank(user1);
        governance.castVote(PROPOSAL_ID, true);
        
        vm.prank(user1);
        vm.expectRevert("Already voted");
        governance.castVote(PROPOSAL_ID, false);
    }

    function testCastVoteFailsWithNoVotingPower() public {
        governance.createProposal(PROPOSAL_ID, START_BLOCK, END_BLOCK);
        vm.roll(START_BLOCK + 10);
        
        address noTokenUser = address(0x999);
        vm.prank(noTokenUser);
        vm.expectRevert("No voting power");
        governance.castVote(PROPOSAL_ID, true);
    }

    function testGetProposalForNonExistentProposal() public {
        (uint256 startBlock, uint256 endBlock, uint256 yesVotes, uint256 noVotes) = governance.getProposal(999);
        assertEq(startBlock, 0);
        assertEq(endBlock, 0);
        assertEq(yesVotes, 0);
        assertEq(noVotes, 0);
    }

    function testFuzzCreateProposal(uint256 proposalId, uint256 startOffset, uint256 duration) public {
        vm.assume(proposalId != 0 && proposalId < type(uint256).max);
        vm.assume(startOffset > 0 && startOffset < 1000000);
        vm.assume(duration > 0 && duration < 1000000);
        
        uint256 currentBlock = block.number;
        uint256 startBlock = currentBlock + startOffset;
        uint256 endBlock = startBlock + duration;
        
        governance.createProposal(proposalId, startBlock, endBlock);
        
        (uint256 returnedStart, uint256 returnedEnd,,) = governance.getProposal(proposalId);
        assertEq(returnedStart, startBlock);
        assertEq(returnedEnd, endBlock);
    }

    function testFuzzCastVote(bool support, uint128 tokenAmount) public {
        // Bound the token amount to reasonable values to avoid overflow
        tokenAmount = uint128(bound(tokenAmount, 1, 1000000 * 10**18));
        
        address voter = address(0x123);
        
        // Make sure we have enough tokens to transfer
        uint256 ourBalance = token.balanceOf(address(this));
        if (ourBalance < tokenAmount) {
            // If we don't have enough, reduce the amount
            tokenAmount = uint128(ourBalance / 2);
        }
        
        if (tokenAmount == 0) return; // Skip if no tokens available
        
        token.transfer(voter, tokenAmount);
        
        governance.createProposal(PROPOSAL_ID, START_BLOCK, END_BLOCK);
        vm.roll(START_BLOCK + 10);
        
        vm.prank(voter);
        governance.castVote(PROPOSAL_ID, support);
        
        (,, uint256 yesVotes, uint256 noVotes) = governance.getProposal(PROPOSAL_ID);
        if (support) {
            assertEq(yesVotes, tokenAmount);
            assertEq(noVotes, 0);
        } else {
            assertEq(yesVotes, 0);
            assertEq(noVotes, tokenAmount);
        }
    }
}