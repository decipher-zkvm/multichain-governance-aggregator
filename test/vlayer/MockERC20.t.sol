// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {MockERC20} from "../../src/vlayer/MockERC20.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract MockERC20Test is Test {
    MockERC20 public mockToken;
    
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public deployer = address(this);
    
    string public constant TOKEN_NAME = "Mock Token";
    string public constant TOKEN_SYMBOL = "MOCK";

    function setUp() public {
        mockToken = new MockERC20(TOKEN_NAME, TOKEN_SYMBOL);
    }

    function testConstructor() public {
        assertEq(mockToken.name(), TOKEN_NAME);
        assertEq(mockToken.symbol(), TOKEN_SYMBOL);
        assertEq(mockToken.decimals(), 18);
        assertEq(mockToken.totalSupply(), 0);
    }

    function testMint() public {
        uint256 mintAmount = 1000 * 10**18;
        
        mockToken.mint(user1, mintAmount);
        
        assertEq(mockToken.balanceOf(user1), mintAmount);
        assertEq(mockToken.totalSupply(), mintAmount);
    }

    function testMintMultiple() public {
        uint256 amount1 = 500 * 10**18;
        uint256 amount2 = 300 * 10**18;
        
        mockToken.mint(user1, amount1);
        mockToken.mint(user2, amount2);
        
        assertEq(mockToken.balanceOf(user1), amount1);
        assertEq(mockToken.balanceOf(user2), amount2);
        assertEq(mockToken.totalSupply(), amount1 + amount2);
    }

    function testMintToSameAddress() public {
        uint256 amount1 = 200 * 10**18;
        uint256 amount2 = 300 * 10**18;
        
        mockToken.mint(user1, amount1);
        mockToken.mint(user1, amount2);
        
        assertEq(mockToken.balanceOf(user1), amount1 + amount2);
        assertEq(mockToken.totalSupply(), amount1 + amount2);
    }

    function testMintZero() public {
        mockToken.mint(user1, 0);
        
        assertEq(mockToken.balanceOf(user1), 0);
        assertEq(mockToken.totalSupply(), 0);
    }

    function testMintByAnyone() public {
        uint256 mintAmount = 1000 * 10**18;
        
        // Test that anyone can mint (no access control)
        vm.prank(user1);
        mockToken.mint(user2, mintAmount);
        
        assertEq(mockToken.balanceOf(user2), mintAmount);
        assertEq(mockToken.totalSupply(), mintAmount);
    }

    function testTransferAfterMint() public {
        uint256 mintAmount = 1000 * 10**18;
        uint256 transferAmount = 300 * 10**18;
        
        mockToken.mint(user1, mintAmount);
        
        vm.prank(user1);
        bool success = mockToken.transfer(user2, transferAmount);
        assertTrue(success);
        
        assertEq(mockToken.balanceOf(user1), mintAmount - transferAmount);
        assertEq(mockToken.balanceOf(user2), transferAmount);
    }

    function testApproveAndTransferFrom() public {
        uint256 mintAmount = 1000 * 10**18;
        uint256 approveAmount = 500 * 10**18;
        uint256 transferAmount = 300 * 10**18;
        
        mockToken.mint(user1, mintAmount);
        
        vm.prank(user1);
        mockToken.approve(user2, approveAmount);
        
        vm.prank(user2);
        bool success = mockToken.transferFrom(user1, deployer, transferAmount);
        assertTrue(success);
        
        assertEq(mockToken.balanceOf(user1), mintAmount - transferAmount);
        assertEq(mockToken.balanceOf(deployer), transferAmount);
        assertEq(mockToken.allowance(user1, user2), approveAmount - transferAmount);
    }

    function testMintLargeAmount() public {
        uint256 largeAmount = type(uint128).max;
        
        mockToken.mint(user1, largeAmount);
        
        assertEq(mockToken.balanceOf(user1), largeAmount);
        assertEq(mockToken.totalSupply(), largeAmount);
    }

    function testMintToZeroAddress() public {
        // Should revert when minting to zero address
        vm.expectRevert();
        mockToken.mint(address(0), 100);
    }

    function testERC20Compliance() public {
        uint256 mintAmount = 1000 * 10**18;
        mockToken.mint(user1, mintAmount);
        
        // Test IERC20 interface compliance
        IERC20 ierc20 = IERC20(address(mockToken));
        
        assertEq(ierc20.totalSupply(), mintAmount);
        assertEq(ierc20.balanceOf(user1), mintAmount);
        
        vm.prank(user1);
        bool success = ierc20.transfer(user2, 100 * 10**18);
        assertTrue(success);
        
        vm.prank(user1);
        success = ierc20.approve(user2, 200 * 10**18);
        assertTrue(success);
        
        assertEq(ierc20.allowance(user1, user2), 200 * 10**18);
    }

    function testFuzzMint(address to, uint256 amount) public {
        vm.assume(to != address(0));
        
        uint256 initialSupply = mockToken.totalSupply();
        uint256 initialBalance = mockToken.balanceOf(to);
        
        mockToken.mint(to, amount);
        
        assertEq(mockToken.balanceOf(to), initialBalance + amount);
        assertEq(mockToken.totalSupply(), initialSupply + amount);
    }

    function testFuzzMintMultipleUsers(uint256 _userCount) public {
        // Use vm.assume to avoid problematic inputs
        vm.assume(_userCount >= 1 && _userCount <= 5);
        uint8 userCount = uint8(_userCount);
        
        uint256 expectedTotalSupply = 0;
        
        for (uint8 i = 0; i < userCount; i++) {
            address user = address(uint160(uint256(i) + 1000)); // Create unique addresses
            uint256 amount = (uint256(i) + 1) * 100 * 10**18; // Reasonable amounts
            
            expectedTotalSupply += amount;
            mockToken.mint(user, amount);
        }
        
        assertEq(mockToken.totalSupply(), expectedTotalSupply);
        
        // Verify balances
        for (uint8 i = 0; i < userCount; i++) {
            address user = address(uint160(uint256(i) + 1000));
            uint256 expectedAmount = (uint256(i) + 1) * 100 * 10**18;
            assertEq(mockToken.balanceOf(user), expectedAmount);
        }
    }

    function testMetadata() public {
        // Verify token metadata
        assertEq(mockToken.name(), TOKEN_NAME);
        assertEq(mockToken.symbol(), TOKEN_SYMBOL);
        assertEq(mockToken.decimals(), 18);
    }

    function testInitialState() public {
        // Verify initial state
        assertEq(mockToken.totalSupply(), 0);
        assertEq(mockToken.balanceOf(deployer), 0);
        assertEq(mockToken.balanceOf(user1), 0);
        assertEq(mockToken.balanceOf(user2), 0);
    }

    function testMintEvents() public {
        uint256 mintAmount = 1000 * 10**18;
        
        // ERC20 _mint should emit Transfer event from zero address
        vm.expectEmit(true, true, false, true);
        emit IERC20.Transfer(address(0), user1, mintAmount);
        
        mockToken.mint(user1, mintAmount);
    }
}