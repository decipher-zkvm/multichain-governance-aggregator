// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract GovernanceAggregator {
    address public verifier;

    struct ProposalAggregate {
        uint256 totalYesVotes;
        uint256 totalNoVotes;
        mapping(uint256 => bool) aggregated; // proposalId => aggregated
    }

    mapping(uint256 => ProposalAggregate) public proposals;

    modifier onlyVerifier() {
        require(msg.sender == verifier, "Only Verifier can call");
        _;
    }

    constructor(address _verifier) {
        verifier = _verifier;
    }

    function addVotes(uint256 proposalId, uint256 yesVotes, uint256 noVotes) external onlyVerifier {
        require(!proposals[proposalId].aggregated[proposalId], "Votes already aggregated for this proposal");
        ProposalAggregate storage aggregate = proposals[proposalId];
        aggregate.totalYesVotes += yesVotes;
        aggregate.totalNoVotes += noVotes;
        proposals[proposalId].aggregated[proposalId] = true;
    }

    function getAggregate(uint256 proposalId) external view returns (uint256 totalYesVotes, uint256 totalNoVotes) {
        ProposalAggregate storage aggregate = proposals[proposalId];
        return (aggregate.totalYesVotes, aggregate.totalNoVotes);
    }
}
