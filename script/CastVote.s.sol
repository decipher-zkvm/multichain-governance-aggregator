// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Governance} from "../src/vlayer/Governance.sol";
import {GovernanceToken} from "../src/vlayer/GovernanceToken.sol";

contract CastVoteScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        Governance governance = Governance(address(0x7Fa1a39FC8F2CE1DB862ac2c127bbd1dBacD62B7));
        
        governance.castVote(1, true);

        (,,uint256 yesVotes, uint256 noVotes) = governance.getProposal(1);
        console.logUint(yesVotes);
        console.logUint(noVotes);

        vm.stopBroadcast();
    }
}
