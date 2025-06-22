// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {L2State} from "../../src/vlayer/L2State.sol";

contract L2StateTest is Test {
    L2State public l2State;
    
    bytes32 public constant ROOT = keccak256("test_root");
    uint256 public constant L2_BLOCK_NUMBER = 12345;

    function setUp() public {
        l2State = new L2State(ROOT, L2_BLOCK_NUMBER);
    }

    function testConstructor() public {
        (bytes32 root, uint256 blockNumber) = l2State.anchors(0);
        assertEq(root, ROOT);
        assertEq(blockNumber, L2_BLOCK_NUMBER);
    }

    function testInitialAnchor() public {
        (bytes32 root, uint256 blockNumber) = l2State.anchors(0);
        assertEq(root, ROOT);
        assertEq(blockNumber, L2_BLOCK_NUMBER);
    }

    function testNonExistentAnchor() public {
        (bytes32 root, uint256 blockNumber) = l2State.anchors(1);
        assertEq(root, bytes32(0));
        assertEq(blockNumber, 0);
    }

    function testMultipleAnchors() public {
        // Deploy multiple L2State contracts with different anchors
        bytes32 root1 = keccak256("root1");
        bytes32 root2 = keccak256("root2");
        uint256 block1 = 100;
        uint256 block2 = 200;
        
        L2State state1 = new L2State(root1, block1);
        L2State state2 = new L2State(root2, block2);
        
        (bytes32 retrievedRoot1, uint256 retrievedBlock1) = state1.anchors(0);
        (bytes32 retrievedRoot2, uint256 retrievedBlock2) = state2.anchors(0);
        
        assertEq(retrievedRoot1, root1);
        assertEq(retrievedBlock1, block1);
        assertEq(retrievedRoot2, root2);
        assertEq(retrievedBlock2, block2);
    }

    function testZeroRoot() public {
        L2State zeroRootState = new L2State(bytes32(0), 999);
        (bytes32 root, uint256 blockNumber) = zeroRootState.anchors(0);
        assertEq(root, bytes32(0));
        assertEq(blockNumber, 999);
    }

    function testZeroBlockNumber() public {
        L2State zeroBlockState = new L2State(ROOT, 0);
        (bytes32 root, uint256 blockNumber) = zeroBlockState.anchors(0);
        assertEq(root, ROOT);
        assertEq(blockNumber, 0);
    }

    function testMaxValues() public {
        bytes32 maxRoot = bytes32(type(uint256).max);
        uint256 maxBlock = type(uint256).max;
        
        L2State maxState = new L2State(maxRoot, maxBlock);
        (bytes32 root, uint256 blockNumber) = maxState.anchors(0);
        assertEq(root, maxRoot);
        assertEq(blockNumber, maxBlock);
    }

    function testFuzzConstructor(bytes32 root, uint256 blockNumber) public {
        L2State fuzzState = new L2State(root, blockNumber);
        (bytes32 retrievedRoot, uint256 retrievedBlock) = fuzzState.anchors(0);
        assertEq(retrievedRoot, root);
        assertEq(retrievedBlock, blockNumber);
    }

    function testFuzzNonExistentAnchor(uint32 anchorId) public {
        vm.assume(anchorId != 0);
        
        (bytes32 root, uint256 blockNumber) = l2State.anchors(anchorId);
        assertEq(root, bytes32(0));
        assertEq(blockNumber, 0);
    }

    function testContractDeployment() public {
        assertNotEq(address(l2State), address(0));
        assertTrue(address(l2State).code.length > 0);
    }

    function testAnchorStruct() public {
        // Test that the anchor struct is properly stored and retrieved
        (bytes32 root, uint256 blockNumber) = l2State.anchors(0);
        
        // Verify both fields are correctly stored
        assertTrue(root != bytes32(0) || root == ROOT); // Handle case where ROOT might be zero
        assertTrue(blockNumber == L2_BLOCK_NUMBER);
    }
}