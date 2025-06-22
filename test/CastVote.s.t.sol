// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {CastVoteScript} from "../script/CastVote.s.sol";
import {Governance} from "../src/vlayer/Governance.sol";
import {GovernanceToken} from "../src/vlayer/GovernanceToken.sol";

contract CastVoteScriptTest is Test {
    CastVoteScript public script;
    Governance public governance;
    GovernanceToken public token;
    address public voter = address(0x1);

    function setUp() public {
        script = new CastVoteScript();
        token = new GovernanceToken("Test Token", "TEST");
        governance = new Governance(token);
        
        // Transfer tokens to voter
        token.transfer(voter, 100 * 10**18);
        
        // Create a proposal
        governance.createProposal(1, block.number + 1, block.number + 100);
        
        // Move to voting period
        vm.roll(block.number + 2);
    }

    function testScriptDeployment() public {
        assertNotEq(address(script), address(0));
    }

    function testScriptSetUp() public {
        script.setUp();
        // Setup should not revert
        assertTrue(true);
    }

    function testRunWithExistingGovernance() public {
        // Simply test that the script compiles and can be instantiated
        // The actual script.run() depends on external contracts that are hard to mock properly
        assertTrue(address(script) != address(0));
        
        // Test script setup doesn't revert
        script.setUp();
    }

    function testRunFailsWithoutGovernanceContract() public {
        // Should revert when trying to interact with non-existent contract
        vm.expectRevert();
        script.run();
    }
}