// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Proof} from "vlayer-0.1.0/Proof.sol";
import {Prover} from "vlayer-0.1.0/Prover.sol";
import {IGovernance} from "./IGovernance.sol";

contract GovernanceResultProver is Prover {
    function crossChainGovernanceResultOf(address governanceContract, uint256 proposalId, uint256[] memory chainIds, uint256 blockNum)
        public
        returns (Proof memory, address, uint256, uint256, uint256)
    {
        uint256 totalYesVotes = 0;
        uint256 totalNoVotes = 0;
        for (uint256 i = 0; i < chainIds.length; i++) {
            setChain(chainIds[i], blockNum);
            (uint256 startBlock, uint256 endBlock, uint256 yesVotes, uint256 noVotes) = IGovernance(governanceContract).getProposal(proposalId);
            require(
                endBlock <= blockNum,
                "Voting is not ended yet"
            );
            totalYesVotes += yesVotes;
            totalNoVotes += noVotes;
        }

        return (proof(), governanceContract, proposalId, totalYesVotes, totalNoVotes);
    }
}
