// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract Governance {
    IERC20 public governanceToken;

    struct Proposal {
        uint256 startBlock;
        uint256 endBlock;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => Proposal) public proposals;

    event CastVote(address indexed voter, uint256 indexed proposalId, bool support, uint256 weight);

    constructor(IERC20 _governanceToken) {
        governanceToken = _governanceToken;
    }

    function createProposal(uint256 proposalId, uint256 startBlock, uint256 endBlock) external {
        // In production, restrict with access control (e.g., onlyOwner)
        require(proposals[proposalId].startBlock == 0, "Proposal already exists");
        require(startBlock < endBlock, "Invalid block range");
        require(block.number <= startBlock, "Start block must be in future");
        require(block.number < endBlock, "End block must be in future");
        Proposal storage proposal = proposals[proposalId];
        proposal.startBlock = startBlock;
        proposal.endBlock = endBlock;
    }

    function castVote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.number >= proposal.startBlock, "Voting not started");
        require(block.number <= proposal.endBlock, "Voting ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");

        uint256 weight = governanceToken.balanceOf(msg.sender);
        require(weight > 0, "No voting power");

        proposal.hasVoted[msg.sender] = true;
        if (support) {
            proposal.yesVotes += weight;
        } else {
            proposal.noVotes += weight;
        }

        emit CastVote(msg.sender, proposalId, support, weight);
    }

    function getProposal(uint256 proposalId)
        external
        view
        returns (uint256 startBlock, uint256 endBlock, uint256 yesVotes, uint256 noVotes)
    {
        Proposal storage proposal = proposals[proposalId];
        return (proposal.startBlock, proposal.endBlock, proposal.yesVotes, proposal.noVotes);
    }
}
