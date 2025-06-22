// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {GovernanceToken} from "../../src/vlayer/GovernanceToken.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract GovernanceTokenTest is Test {
    GovernanceToken public token;
    
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public deployer = address(this);
    
    string public constant TOKEN_NAME = "Test Governance Token";
    string public constant TOKEN_SYMBOL = "TGT";
    uint256 public constant INITIAL_SUPPLY = 1000000 * 10**18;

    function setUp() public {
        token = new GovernanceToken(TOKEN_NAME, TOKEN_SYMBOL);
    }

    function testConstructor() public {
        assertEq(token.name(), TOKEN_NAME);
        assertEq(token.symbol(), TOKEN_SYMBOL);
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(deployer), INITIAL_SUPPLY);
    }

    function testInitialSupplyMintedToDeployer() public {
        assertEq(token.balanceOf(address(this)), INITIAL_SUPPLY);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }

    function testTransfer() public {
        uint256 transferAmount = 1000 * 10**18;
        
        bool success = token.transfer(user1, transferAmount);
        assertTrue(success);
        
        assertEq(token.balanceOf(user1), transferAmount);
        assertEq(token.balanceOf(deployer), INITIAL_SUPPLY - transferAmount);
    }

    function testTransferFrom() public {
        uint256 approveAmount = 2000 * 10**18;
        uint256 transferAmount = 1500 * 10**18;
        
        // Approve user1 to spend tokens
        token.approve(user1, approveAmount);
        assertEq(token.allowance(deployer, user1), approveAmount);
        
        // Transfer from deployer to user2 via user1
        vm.prank(user1);
        bool success = token.transferFrom(deployer, user2, transferAmount);
        assertTrue(success);
        
        assertEq(token.balanceOf(user2), transferAmount);
        assertEq(token.balanceOf(deployer), INITIAL_SUPPLY - transferAmount);
        assertEq(token.allowance(deployer, user1), approveAmount - transferAmount);
    }

    function testApprove() public {
        uint256 approveAmount = 5000 * 10**18;
        
        bool success = token.approve(user1, approveAmount);
        assertTrue(success);
        
        assertEq(token.allowance(deployer, user1), approveAmount);
    }

    function testTransferFailsWithInsufficientBalance() public {
        uint256 excessiveAmount = INITIAL_SUPPLY + 1;
        
        vm.expectRevert();
        token.transfer(user1, excessiveAmount);
    }

    function testTransferFromFailsWithInsufficientAllowance() public {
        uint256 transferAmount = 1000 * 10**18;
        uint256 smallAllowance = 500 * 10**18;
        
        token.approve(user1, smallAllowance);
        
        vm.prank(user1);
        vm.expectRevert();
        token.transferFrom(deployer, user2, transferAmount);
    }

    function testTransferFromFailsWithInsufficientBalance() public {
        // Give user1 some tokens but not enough
        token.transfer(user1, 500 * 10**18);
        
        // User1 approves user2 to spend more than they have
        vm.prank(user1);
        token.approve(user2, 1000 * 10**18);
        
        // Transfer should fail
        vm.prank(user2);
        vm.expectRevert();
        token.transferFrom(user1, deployer, 1000 * 10**18);
    }

    function testZeroTransfer() public {
        bool success = token.transfer(user1, 0);
        assertTrue(success);
        
        assertEq(token.balanceOf(user1), 0);
        assertEq(token.balanceOf(deployer), INITIAL_SUPPLY);
    }

    function testSelfTransfer() public {
        uint256 transferAmount = 1000 * 10**18;
        
        bool success = token.transfer(deployer, transferAmount);
        assertTrue(success);
        
        assertEq(token.balanceOf(deployer), INITIAL_SUPPLY);
    }

    function testMultipleTransfers() public {
        uint256 amount1 = 1000 * 10**18;
        uint256 amount2 = 2000 * 10**18;
        
        token.transfer(user1, amount1);
        token.transfer(user2, amount2);
        
        assertEq(token.balanceOf(user1), amount1);
        assertEq(token.balanceOf(user2), amount2);
        assertEq(token.balanceOf(deployer), INITIAL_SUPPLY - amount1 - amount2);
    }

    function testAllowanceManagement() public {
        uint256 initialAllowance = 1000 * 10**18;
        uint256 newAllowance = 500 * 10**18;
        
        token.approve(user1, initialAllowance);
        assertEq(token.allowance(deployer, user1), initialAllowance);
        
        // Update allowance to new value
        token.approve(user1, newAllowance);
        assertEq(token.allowance(deployer, user1), newAllowance);
        
        // Set allowance to zero
        token.approve(user1, 0);
        assertEq(token.allowance(deployer, user1), 0);
    }

    function testFuzzTransfer(address to, uint256 amount) public {
        vm.assume(to != address(0));
        amount = bound(amount, 0, INITIAL_SUPPLY);
        
        bool success = token.transfer(to, amount);
        assertTrue(success);
        
        assertEq(token.balanceOf(to), amount);
        if (to != deployer) {
            assertEq(token.balanceOf(deployer), INITIAL_SUPPLY - amount);
        }
    }

    function testFuzzApprove(address spender, uint256 amount) public {
        vm.assume(spender != address(0));
        
        bool success = token.approve(spender, amount);
        assertTrue(success);
        
        assertEq(token.allowance(deployer, spender), amount);
    }

    function testERC20Compliance() public {
        // Test that it implements IERC20
        IERC20 ierc20 = IERC20(address(token));
        
        assertEq(ierc20.totalSupply(), INITIAL_SUPPLY);
        assertEq(ierc20.balanceOf(deployer), INITIAL_SUPPLY);
        
        bool success = ierc20.transfer(user1, 1000 * 10**18);
        assertTrue(success);
        
        success = ierc20.approve(user1, 500 * 10**18);
        assertTrue(success);
        
        assertEq(ierc20.allowance(deployer, user1), 500 * 10**18);
    }

    function testTokenMetadata() public {
        // Verify token metadata is correctly set
        assertEq(token.name(), TOKEN_NAME);
        assertEq(token.symbol(), TOKEN_SYMBOL);
        assertEq(token.decimals(), 18);
    }

    function testDeployerCanTransferAll() public {
        // Deployer should be able to transfer all tokens
        token.transfer(user1, INITIAL_SUPPLY);
        
        assertEq(token.balanceOf(user1), INITIAL_SUPPLY);
        assertEq(token.balanceOf(deployer), 0);
    }
}