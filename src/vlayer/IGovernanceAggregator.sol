// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";

interface IGovernanceAggregator {
    function addVotes(uint256 proposalId, uint256 yesVotes, uint256 noVotes) external;
    function getAggregate(uint256 proposalId) external;
}
