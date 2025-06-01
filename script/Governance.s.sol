// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Governance} from "../src/vlayer/Governance.sol";
import {GovernanceToken} from "../src/vlayer/GovernanceToken.sol";

contract GovernanceScript is Script {
    GovernanceToken public governanceToken;
    Governance public governance;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        governanceToken = new GovernanceToken("Governance Token", "GVT");
        governance = new Governance(governanceToken);

        console.logString("deployed governance token and governance contract");
        console.logString("Governance contract deployed at");
        console.logAddress(address(governance));

        governance.createProposal(1, block.number + 5, block.number + 100);

        console.logString("created proposal");

        vm.stopBroadcast();
    }
}
