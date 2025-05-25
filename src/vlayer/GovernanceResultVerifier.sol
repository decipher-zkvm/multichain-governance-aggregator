// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {GovernanceResultProver, ProposalResult} from "./GovernanceResultProver.sol";
import {IGovernanceAggregator} from "./IGovernanceAggregator.sol";

import {Proof} from "vlayer-0.1.0/Proof.sol";
import {Verifier} from "vlayer-0.1.0/Verifier.sol";

contract GovernanceResultVerifier is Verifier {
    address public prover;
    mapping(uint256 => bool) public aggregated;

    constructor(address _prover) {
        prover = _prover;
    }

    function aggregate(Proof calldata, address governanceContract, uint256 proposalId, ProposalResult[] memory results)
        public
        onlyVerified(prover, GovernanceResultProver.crossChainGovernanceResultOf.selector)
    {
        require(!aggregated[proposalId], "Already aggregated");

        uint256 totalYesVotes = 0;
        uint256 totalNoVotes = 0;

        for (uint256 i = 0; i < results.length; i++) {
            totalYesVotes += results[i].yesVotes;
            totalNoVotes += results[i].noVotes;
        }
        IGovernanceAggregator(governanceContract).addVotes(proposalId, totalYesVotes, totalNoVotes);

        aggregated[proposalId] = true;
    }
}
