// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Proof} from "vlayer-0.1.0/Proof.sol";
import {Prover} from "vlayer-0.1.0/Prover.sol";
import {IGovernance} from "./IGovernance.sol";

struct ProposalResult {
    address addr;
    uint256 chainId;
    uint256 proposalId;
    uint256 blockNumber;
    uint256 yesVotes;
    uint256 noVotes;
}

contract GovernanceResultProver is Prover {
    function crossChainGovernanceResultOf(address governanceContract, uint256 proposalId, ProposalResult[] memory results)
        public
        returns (Proof memory, address, uint256, ProposalResult[] memory)
    {
        uint256 totalYesVotes = 0;
        uint256 totalNoVotes = 0;
        for (uint256 i = 0; i < results.length; i++) {
            setChain(results[i].chainId, results[i].blockNumber);
            (uint256 startBlock, uint256 endBlock, uint256 yesVotes, uint256 noVotes) = IGovernance(results[i].addr).getProposal(results[i].proposalId);
            results[i].yesVotes = yesVotes;
            results[i].noVotes = noVotes;
            
            totalYesVotes += yesVotes;
            totalNoVotes += noVotes;
            require(
                endBlock <= results[i].blockNumber,
                "Voting is not ended yet"
            );
        }

        return (proof(), governanceContract, proposalId, results);
    }
}