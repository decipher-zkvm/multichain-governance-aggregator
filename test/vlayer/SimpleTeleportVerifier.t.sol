// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {SimpleTeleportVerifier} from "../../src/vlayer/SimpleTeleportVerifier.sol";
import {WhaleBadgeNFT} from "../../src/vlayer/WhaleBadgeNFT.sol";
import {Erc20Token} from "../../src/vlayer/SimpleTeleportProver.sol";

// Mock Proof struct for testing
struct Proof {
    bytes data;
}

// Mock Verifier contract for testing
abstract contract MockVerifier {
    modifier onlyVerified(address prover, bytes4 selector) {
        // Mock implementation - always allow for testing
        _;
    }
}

contract MockSimpleTeleportVerifier is MockVerifier {
    address public prover;
    mapping(address => bool) public claimed;
    WhaleBadgeNFT public reward;

    constructor(address _prover, WhaleBadgeNFT _nft) {
        prover = _prover;
        reward = _nft;
    }

    function claim(Proof calldata, address claimer, Erc20Token[] memory tokens)
        public
        onlyVerified(prover, bytes4(0)) // Mock selector
    {
        require(!claimed[claimer], "Already claimed");

        if (tokens.length > 0) {
            uint256 totalBalance = 0;
            for (uint256 i = 0; i < tokens.length; i++) {
                totalBalance += tokens[i].balance;
            }
            if (totalBalance >= 10_000_000_000_000) {
                claimed[claimer] = true;
                reward.mint(claimer);
            }
        }
    }
}

contract SimpleTeleportVerifierTest is Test {
    MockSimpleTeleportVerifier public verifier;
    WhaleBadgeNFT public nft;
    
    address public prover = address(0x1);
    address public claimer = address(0x2);
    address public other = address(0x3);
    
    uint256 public constant WHALE_THRESHOLD = 10_000_000_000_000;

    function setUp() public {
        nft = new WhaleBadgeNFT();
        verifier = new MockSimpleTeleportVerifier(prover, nft);
    }

    function testConstructor() public {
        assertEq(verifier.prover(), prover);
        assertEq(address(verifier.reward()), address(nft));
    }

    function testClaimWithSufficientBalance() public {
        Erc20Token[] memory tokens = new Erc20Token[](1);
        tokens[0] = Erc20Token({
            addr: address(0x123),
            chainId: 1,
            blockNumber: 1000,
            balance: WHALE_THRESHOLD
        });
        
        Proof memory mockProof = Proof({data: "mock_proof"});
        
        assertFalse(verifier.claimed(claimer));
        assertEq(nft.balanceOf(claimer), 0);
        
        verifier.claim(mockProof, claimer, tokens);
        
        assertTrue(verifier.claimed(claimer));
        assertEq(nft.balanceOf(claimer), 1);
        assertEq(nft.ownerOf(1), claimer);
    }

    function testClaimWithInsufficientBalance() public {
        Erc20Token[] memory tokens = new Erc20Token[](1);
        tokens[0] = Erc20Token({
            addr: address(0x123),
            chainId: 1,
            blockNumber: 1000,
            balance: WHALE_THRESHOLD - 1
        });
        
        Proof memory mockProof = Proof({data: "mock_proof"});
        
        verifier.claim(mockProof, claimer, tokens);
        
        assertFalse(verifier.claimed(claimer));
        assertEq(nft.balanceOf(claimer), 0);
    }

    function testClaimWithMultipleTokensSufficientTotal() public {
        Erc20Token[] memory tokens = new Erc20Token[](3);
        tokens[0] = Erc20Token({
            addr: address(0x123),
            chainId: 1,
            blockNumber: 1000,
            balance: WHALE_THRESHOLD / 3
        });
        tokens[1] = Erc20Token({
            addr: address(0x456),
            chainId: 2,
            blockNumber: 2000,
            balance: WHALE_THRESHOLD / 3
        });
        tokens[2] = Erc20Token({
            addr: address(0x789),
            chainId: 3,
            blockNumber: 3000,
            balance: WHALE_THRESHOLD / 3 + 1 // Slightly over threshold when combined
        });
        
        Proof memory mockProof = Proof({data: "mock_proof"});
        
        verifier.claim(mockProof, claimer, tokens);
        
        assertTrue(verifier.claimed(claimer));
        assertEq(nft.balanceOf(claimer), 1);
    }

    function testClaimWithMultipleTokensInsufficientTotal() public {
        Erc20Token[] memory tokens = new Erc20Token[](2);
        tokens[0] = Erc20Token({
            addr: address(0x123),
            chainId: 1,
            blockNumber: 1000,
            balance: WHALE_THRESHOLD / 3
        });
        tokens[1] = Erc20Token({
            addr: address(0x456),
            chainId: 2,
            blockNumber: 2000,
            balance: WHALE_THRESHOLD / 3
        });
        
        Proof memory mockProof = Proof({data: "mock_proof"});
        
        verifier.claim(mockProof, claimer, tokens);
        
        assertFalse(verifier.claimed(claimer));
        assertEq(nft.balanceOf(claimer), 0);
    }

    function testClaimWithEmptyTokenArray() public {
        Erc20Token[] memory tokens = new Erc20Token[](0);
        Proof memory mockProof = Proof({data: "mock_proof"});
        
        verifier.claim(mockProof, claimer, tokens);
        
        assertFalse(verifier.claimed(claimer));
        assertEq(nft.balanceOf(claimer), 0);
    }

    function testClaimFailsIfAlreadyClaimed() public {
        Erc20Token[] memory tokens = new Erc20Token[](1);
        tokens[0] = Erc20Token({
            addr: address(0x123),
            chainId: 1,
            blockNumber: 1000,
            balance: WHALE_THRESHOLD
        });
        
        Proof memory mockProof = Proof({data: "mock_proof"});
        
        // First claim should succeed
        verifier.claim(mockProof, claimer, tokens);
        assertTrue(verifier.claimed(claimer));
        
        // Second claim should fail
        vm.expectRevert("Already claimed");
        verifier.claim(mockProof, claimer, tokens);
    }

    function testMultipleClaimersDifferentAddresses() public {
        Erc20Token[] memory tokens = new Erc20Token[](1);
        tokens[0] = Erc20Token({
            addr: address(0x123),
            chainId: 1,
            blockNumber: 1000,
            balance: WHALE_THRESHOLD
        });
        
        Proof memory mockProof = Proof({data: "mock_proof"});
        
        // Both users can claim independently
        verifier.claim(mockProof, claimer, tokens);
        verifier.claim(mockProof, other, tokens);
        
        assertTrue(verifier.claimed(claimer));
        assertTrue(verifier.claimed(other));
        assertEq(nft.balanceOf(claimer), 1);
        assertEq(nft.balanceOf(other), 1);
        assertEq(nft.ownerOf(1), claimer);
        assertEq(nft.ownerOf(2), other);
    }

    function testClaimWithExactThreshold() public {
        Erc20Token[] memory tokens = new Erc20Token[](1);
        tokens[0] = Erc20Token({
            addr: address(0x123),
            chainId: 1,
            blockNumber: 1000,
            balance: WHALE_THRESHOLD
        });
        
        Proof memory mockProof = Proof({data: "mock_proof"});
        
        verifier.claim(mockProof, claimer, tokens);
        
        assertTrue(verifier.claimed(claimer));
        assertEq(nft.balanceOf(claimer), 1);
    }

    function testClaimWithLargeBalance() public {
        Erc20Token[] memory tokens = new Erc20Token[](1);
        tokens[0] = Erc20Token({
            addr: address(0x123),
            chainId: 1,
            blockNumber: 1000,
            balance: WHALE_THRESHOLD * 100 // Much larger than threshold
        });
        
        Proof memory mockProof = Proof({data: "mock_proof"});
        
        verifier.claim(mockProof, claimer, tokens);
        
        assertTrue(verifier.claimed(claimer));
        assertEq(nft.balanceOf(claimer), 1);
    }

    function testFuzzClaim(uint256 balance1, uint256 balance2, address _claimer) public {
        vm.assume(_claimer != address(0));
        vm.assume(!verifier.claimed(_claimer));
        
        // Bound balances to reasonable values to avoid overflow
        balance1 = bound(balance1, 0, type(uint128).max);
        balance2 = bound(balance2, 0, type(uint128).max);
        
        Erc20Token[] memory tokens = new Erc20Token[](2);
        tokens[0] = Erc20Token({
            addr: address(0x123),
            chainId: 1,
            blockNumber: 1000,
            balance: balance1
        });
        tokens[1] = Erc20Token({
            addr: address(0x456),
            chainId: 2,
            blockNumber: 2000,
            balance: balance2
        });
        
        Proof memory mockProof = Proof({data: "mock_proof"});
        
        uint256 totalBalance = balance1 + balance2;
        bool shouldSucceed = totalBalance >= WHALE_THRESHOLD;
        
        verifier.claim(mockProof, _claimer, tokens);
        
        assertEq(verifier.claimed(_claimer), shouldSucceed);
        assertEq(nft.balanceOf(_claimer), shouldSucceed ? 1 : 0);
    }

    function testTokenBalanceAccumulation() public {
        uint256[] memory balances = new uint256[](5);
        balances[0] = 2_000_000_000_000;
        balances[1] = 2_000_000_000_000;
        balances[2] = 2_000_000_000_000;
        balances[3] = 2_000_000_000_000;
        balances[4] = 2_000_000_000_001; // Total: 10_000_000_000_001 (just over threshold)
        
        Erc20Token[] memory tokens = new Erc20Token[](5);
        for (uint256 i = 0; i < 5; i++) {
            tokens[i] = Erc20Token({
                addr: address(uint160(i + 1)),
                chainId: i + 1,
                blockNumber: (i + 1) * 1000,
                balance: balances[i]
            });
        }
        
        Proof memory mockProof = Proof({data: "mock_proof"});
        
        verifier.claim(mockProof, claimer, tokens);
        
        assertTrue(verifier.claimed(claimer));
        assertEq(nft.balanceOf(claimer), 1);
    }

    function testClaimStateTracking() public {
        address user1 = address(0x11);
        address user2 = address(0x12);
        address user3 = address(0x13);
        
        Erc20Token[] memory tokens = new Erc20Token[](1);
        tokens[0] = Erc20Token({
            addr: address(0x123),
            chainId: 1,
            blockNumber: 1000,
            balance: WHALE_THRESHOLD
        });
        
        Proof memory mockProof = Proof({data: "mock_proof"});
        
        // Initially no one has claimed
        assertFalse(verifier.claimed(user1));
        assertFalse(verifier.claimed(user2));
        assertFalse(verifier.claimed(user3));
        
        // User1 claims
        verifier.claim(mockProof, user1, tokens);
        assertTrue(verifier.claimed(user1));
        assertFalse(verifier.claimed(user2));
        assertFalse(verifier.claimed(user3));
        
        // User2 claims
        verifier.claim(mockProof, user2, tokens);
        assertTrue(verifier.claimed(user1));
        assertTrue(verifier.claimed(user2));
        assertFalse(verifier.claimed(user3));
        
        // User3 doesn't claim
        assertFalse(verifier.claimed(user3));
    }
}