// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";

interface IGovernance {
    function createProposal(uint256 proposalId, uint256 startBlock, uint256 endBlock) external;
    function castVote(uint256 proposalId, bool support) external;
    function getProposal(uint256 proposalId) external view returns (
        uint256 startBlock,
        uint256 endBlock,
        uint256 yesVotes,
        uint256 noVotes
    );
    function governanceToken() external view returns (IERC20);
}