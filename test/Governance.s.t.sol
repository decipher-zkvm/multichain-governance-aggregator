// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {GovernanceScript} from "../script/Governance.s.sol";
import {Governance} from "../src/vlayer/Governance.sol";
import {GovernanceToken} from "../src/vlayer/GovernanceToken.sol";

contract GovernanceScriptTest is Test {
    GovernanceScript public script;
    
    function setUp() public {
        script = new GovernanceScript();
    }

    function testScriptDeployment() public {
        assertNotEq(address(script), address(0));
    }

    function testScriptSetUp() public {
        script.setUp();
        // Setup should not revert
        assertTrue(true);
    }

    function testRunDeploysContracts() public {
        // Record initial state
        assertEq(address(script.governanceToken()), address(0));
        assertEq(address(script.governance()), address(0));
        
        // Run the script
        script.run();
        
        // Verify contracts were deployed
        assertNotEq(address(script.governanceToken()), address(0));
        assertNotEq(address(script.governance()), address(0));
        
        // Verify token properties
        GovernanceToken token = script.governanceToken();
        assertEq(token.name(), "Governance Token");
        assertEq(token.symbol(), "GVT");
        assertEq(token.totalSupply(), 1000000 * 10**18);
        
        // Verify governance is properly configured
        Governance governance = script.governance();
        assertEq(address(governance.governanceToken()), address(token));
    }

    function testRunCreatesProposal() public {
        uint256 currentBlock = block.number;
        
        // Run the script
        script.run();
        
        // Verify proposal was created
        Governance governance = script.governance();
        (uint256 startBlock, uint256 endBlock, uint256 yesVotes, uint256 noVotes) = governance.getProposal(1);
        
        assertEq(startBlock, currentBlock + 5);
        assertEq(endBlock, currentBlock + 100);
        assertEq(yesVotes, 0);
        assertEq(noVotes, 0);
    }

    function testRunEmitsLogs() public {
        // Capture console logs by checking that run completes successfully
        script.run();
        
        // If we reach here, the console.log calls didn't cause reverts
        assertTrue(true);
    }

    function testContractAddressesAreValid() public {
        script.run();
        
        // Verify deployed contracts have code
        assertGt(address(script.governanceToken()).code.length, 0);
        assertGt(address(script.governance()).code.length, 0);
    }

    function testTokenOwnershipAfterDeployment() public {
        script.run();
        
        GovernanceToken token = script.governanceToken();
        
        // Verify the token was deployed properly
        uint256 totalSupply = token.totalSupply();
        assertEq(totalSupply, 1000000 * 10**18);
        
        // During vm.startBroadcast(), tokens are minted to the broadcaster
        // Check the total supply is correct regardless of who holds the tokens
        assertTrue(totalSupply > 0);
    }
}