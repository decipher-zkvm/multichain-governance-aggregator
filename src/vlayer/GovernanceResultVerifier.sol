// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {GovernanceResultProver} from "./GovernanceResultProver.sol";
import {IGovernanceAggregator} from "./IGovernanceAggregator.sol";

import {Proof} from "vlayer-0.1.0/Proof.sol";
import {Verifier} from "vlayer-0.1.0/Verifier.sol";

contract GovernanceResultVerifier is Verifier {
    address public prover;

    struct ProposalAggregated {
        address governanceContract;
        uint256 totalYesVotes;
        uint256 totalNoVotes;
        bool aggregated;
    }

    mapping(uint256 => ProposalAggregated) public proposals;

    constructor(address _prover) {
        prover = _prover;
    }

    function aggregate(Proof calldata, address governanceContract, uint256 proposalId, uint256 totalYesVotes, uint256 totalNoVotes)
        public
        onlyVerified(prover, GovernanceResultProver.crossChainGovernanceResultOf.selector)
    {
        require(!proposals[proposalId].aggregated, "Already aggregated");

        proposals[proposalId].governanceContract = governanceContract;
        proposals[proposalId].totalYesVotes = totalYesVotes;
        proposals[proposalId].totalNoVotes = totalNoVotes;
        proposals[proposalId].aggregated = true;
    }

    function getAggregate(uint256 proposalId) external view returns (uint256 totalYesVotes, uint256 totalNoVotes) {
        return (proposals[proposalId].totalYesVotes, proposals[proposalId].totalNoVotes);
    }
}