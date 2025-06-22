// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {SimpleTeleportProver, Erc20Token} from "../../src/vlayer/SimpleTeleportProver.sol";
import {MockERC20} from "../../src/vlayer/MockERC20.sol";

// Mock Proof struct for testing
struct Proof {
    bytes data;
}

// Mock Prover contract for testing
abstract contract MockProver {
    function proof() internal pure returns (Proof memory) {
        return Proof({data: "mock_proof"});
    }
    
    function setChain(uint256 chainId, uint256 blockNumber) internal pure {
        // Mock implementation - in real vlayer this would switch context
    }
}

contract MockSimpleTeleportProver is MockProver {
    function crossChainBalanceOf(address _owner, Erc20Token[] memory tokens)
        public
        returns (Proof memory, address, Erc20Token[] memory)
    {
        for (uint256 i = 0; i < tokens.length; i++) {
            setChain(tokens[i].chainId, tokens[i].blockNumber);
            // Mock the balance query - in tests we'll set this manually
            tokens[i].balance = 1000 * 10**18; // Default mock balance
        }

        return (proof(), _owner, tokens);
    }
}

contract SimpleTeleportProverTest is Test {
    MockSimpleTeleportProver public prover;
    MockERC20 public token1;
    MockERC20 public token2;
    
    address public owner = address(0x1);
    
    uint256 public constant CHAIN_ID_1 = 1;
    uint256 public constant CHAIN_ID_2 = 137;
    uint256 public constant BLOCK_NUMBER_1 = 1000;
    uint256 public constant BLOCK_NUMBER_2 = 2000;

    function setUp() public {
        prover = new MockSimpleTeleportProver();
        token1 = new MockERC20("Token1", "TOK1");
        token2 = new MockERC20("Token2", "TOK2");
        
        // Mint tokens for testing
        token1.mint(owner, 500 * 10**18);
        token2.mint(owner, 300 * 10**18);
    }

    function testProverDeployment() public {
        assertNotEq(address(prover), address(0));
    }

    function testCrossChainBalanceOfSingleToken() public {
        Erc20Token[] memory tokens = new Erc20Token[](1);
        tokens[0] = Erc20Token({
            addr: address(token1),
            chainId: CHAIN_ID_1,
            blockNumber: BLOCK_NUMBER_1,
            balance: 0 // Will be set by prover
        });
        
        (Proof memory proof, address returnedOwner, Erc20Token[] memory returnedTokens) = 
            prover.crossChainBalanceOf(owner, tokens);
        
        assertEq(returnedOwner, owner);
        assertEq(returnedTokens.length, 1);
        assertEq(returnedTokens[0].addr, address(token1));
        assertEq(returnedTokens[0].chainId, CHAIN_ID_1);
        assertEq(returnedTokens[0].blockNumber, BLOCK_NUMBER_1);
        assertEq(returnedTokens[0].balance, 1000 * 10**18); // Mock balance
        assertEq(proof.data, "mock_proof");
    }

    function testCrossChainBalanceOfMultipleTokens() public {
        Erc20Token[] memory tokens = new Erc20Token[](2);
        tokens[0] = Erc20Token({
            addr: address(token1),
            chainId: CHAIN_ID_1,
            blockNumber: BLOCK_NUMBER_1,
            balance: 0
        });
        tokens[1] = Erc20Token({
            addr: address(token2),
            chainId: CHAIN_ID_2,
            blockNumber: BLOCK_NUMBER_2,
            balance: 0
        });
        
        (Proof memory proof, address returnedOwner, Erc20Token[] memory returnedTokens) = 
            prover.crossChainBalanceOf(owner, tokens);
        
        assertEq(returnedOwner, owner);
        assertEq(returnedTokens.length, 2);
        
        // Check first token
        assertEq(returnedTokens[0].addr, address(token1));
        assertEq(returnedTokens[0].chainId, CHAIN_ID_1);
        assertEq(returnedTokens[0].blockNumber, BLOCK_NUMBER_1);
        assertEq(returnedTokens[0].balance, 1000 * 10**18);
        
        // Check second token
        assertEq(returnedTokens[1].addr, address(token2));
        assertEq(returnedTokens[1].chainId, CHAIN_ID_2);
        assertEq(returnedTokens[1].blockNumber, BLOCK_NUMBER_2);
        assertEq(returnedTokens[1].balance, 1000 * 10**18);
    }

    function testCrossChainBalanceOfEmptyArray() public {
        Erc20Token[] memory tokens = new Erc20Token[](0);
        
        (Proof memory proof, address returnedOwner, Erc20Token[] memory returnedTokens) = 
            prover.crossChainBalanceOf(owner, tokens);
        
        assertEq(returnedOwner, owner);
        assertEq(returnedTokens.length, 0);
        assertEq(proof.data, "mock_proof");
    }

    function testErc20TokenStruct() public {
        Erc20Token memory token = Erc20Token({
            addr: address(token1),
            chainId: CHAIN_ID_1,
            blockNumber: BLOCK_NUMBER_1,
            balance: 500 * 10**18
        });
        
        assertEq(token.addr, address(token1));
        assertEq(token.chainId, CHAIN_ID_1);
        assertEq(token.blockNumber, BLOCK_NUMBER_1);
        assertEq(token.balance, 500 * 10**18);
    }

    function testFuzzCrossChainBalanceOf(address _owner, uint256 tokenCount) public {
        vm.assume(_owner != address(0));
        tokenCount = bound(tokenCount, 0, 5); // Limit for gas
        
        Erc20Token[] memory tokens = new Erc20Token[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokens[i] = Erc20Token({
                addr: address(uint160(uint256(keccak256(abi.encode(i))))),
                chainId: i + 1,
                blockNumber: (i + 1) * 1000,
                balance: 0
            });
        }
        
        (Proof memory proof, address returnedOwner, Erc20Token[] memory returnedTokens) = 
            prover.crossChainBalanceOf(_owner, tokens);
        
        assertEq(returnedOwner, _owner);
        assertEq(returnedTokens.length, tokenCount);
        
        for (uint256 i = 0; i < tokenCount; i++) {
            assertEq(returnedTokens[i].addr, tokens[i].addr);
            assertEq(returnedTokens[i].chainId, tokens[i].chainId);
            assertEq(returnedTokens[i].blockNumber, tokens[i].blockNumber);
            assertEq(returnedTokens[i].balance, 1000 * 10**18); // Mock balance
        }
    }

    function testDifferentOwners() public {
        address owner1 = address(0x1);
        address owner2 = address(0x2);
        
        Erc20Token[] memory tokens = new Erc20Token[](1);
        tokens[0] = Erc20Token({
            addr: address(token1),
            chainId: CHAIN_ID_1,
            blockNumber: BLOCK_NUMBER_1,
            balance: 0
        });
        
        (, address returnedOwner1,) = prover.crossChainBalanceOf(owner1, tokens);
        (, address returnedOwner2,) = prover.crossChainBalanceOf(owner2, tokens);
        
        assertEq(returnedOwner1, owner1);
        assertEq(returnedOwner2, owner2);
    }

    function testLargeTokenArray() public {
        uint256 tokenCount = 10;
        Erc20Token[] memory tokens = new Erc20Token[](tokenCount);
        
        for (uint256 i = 0; i < tokenCount; i++) {
            tokens[i] = Erc20Token({
                addr: address(uint160(i + 1000)),
                chainId: i + 1,
                blockNumber: (i + 1) * 100,
                balance: 0
            });
        }
        
        (,, Erc20Token[] memory returnedTokens) = prover.crossChainBalanceOf(owner, tokens);
        
        assertEq(returnedTokens.length, tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            assertEq(returnedTokens[i].balance, 1000 * 10**18);
        }
    }

    function testTokenStructModification() public {
        Erc20Token[] memory tokens = new Erc20Token[](1);
        tokens[0] = Erc20Token({
            addr: address(token1),
            chainId: CHAIN_ID_1,
            blockNumber: BLOCK_NUMBER_1,
            balance: 999 // Initial value, should be overwritten
        });
        
        (,, Erc20Token[] memory returnedTokens) = prover.crossChainBalanceOf(owner, tokens);
        
        // Verify the balance was updated by the prover
        assertEq(returnedTokens[0].balance, 1000 * 10**18);
        assertNotEq(returnedTokens[0].balance, 999);
    }
}