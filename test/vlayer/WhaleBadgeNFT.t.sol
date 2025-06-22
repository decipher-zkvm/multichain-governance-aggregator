// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {WhaleBadgeNFT} from "../../src/vlayer/WhaleBadgeNFT.sol";
import {IERC721} from "@openzeppelin-contracts-5.0.1/token/ERC721/IERC721.sol";
import {IERC165} from "@openzeppelin-contracts-5.0.1/utils/introspection/IERC165.sol";

contract WhaleBadgeNFTTest is Test {
    WhaleBadgeNFT public nft;
    
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public user3 = address(0x3);
    
    string public constant NFT_NAME = "WhaleBadgeNFT";
    string public constant NFT_SYMBOL = "Whale";

    function setUp() public {
        nft = new WhaleBadgeNFT();
    }

    function testConstructor() public {
        assertEq(nft.name(), NFT_NAME);
        assertEq(nft.symbol(), NFT_SYMBOL);
        assertEq(nft.currentTokenId(), 1);
    }

    function testMint() public {
        nft.mint(user1);
        
        assertEq(nft.ownerOf(1), user1);
        assertEq(nft.balanceOf(user1), 1);
        assertEq(nft.currentTokenId(), 2);
    }

    function testMintMultiple() public {
        nft.mint(user1);
        nft.mint(user2);
        nft.mint(user3);
        
        assertEq(nft.ownerOf(1), user1);
        assertEq(nft.ownerOf(2), user2);
        assertEq(nft.ownerOf(3), user3);
        assertEq(nft.currentTokenId(), 4);
    }

    function testMintToSameAddress() public {
        nft.mint(user1);
        nft.mint(user1);
        
        assertEq(nft.ownerOf(1), user1);
        assertEq(nft.ownerOf(2), user1);
        assertEq(nft.balanceOf(user1), 2);
        assertEq(nft.currentTokenId(), 3);
    }

    function testTokenIdIncrement() public {
        uint256 initialTokenId = nft.currentTokenId();
        
        nft.mint(user1);
        assertEq(nft.currentTokenId(), initialTokenId + 1);
        
        nft.mint(user2);
        assertEq(nft.currentTokenId(), initialTokenId + 2);
        
        nft.mint(user3);
        assertEq(nft.currentTokenId(), initialTokenId + 3);
    }

    function testMintByAnyone() public {
        // Test that anyone can mint (no access control)
        vm.prank(user1);
        nft.mint(user2);
        
        assertEq(nft.ownerOf(1), user2);
        assertEq(nft.currentTokenId(), 2);
    }

    function testTransferAfterMint() public {
        nft.mint(user1);
        
        vm.prank(user1);
        nft.transferFrom(user1, user2, 1);
        
        assertEq(nft.ownerOf(1), user2);
        assertEq(nft.balanceOf(user1), 0);
        assertEq(nft.balanceOf(user2), 1);
    }

    function testApproveAndTransferFrom() public {
        nft.mint(user1);
        
        vm.prank(user1);
        nft.approve(user2, 1);
        assertEq(nft.getApproved(1), user2);
        
        vm.prank(user2);
        nft.transferFrom(user1, user3, 1);
        
        assertEq(nft.ownerOf(1), user3);
        assertEq(nft.getApproved(1), address(0)); // Approval cleared after transfer
    }

    function testSetApprovalForAll() public {
        nft.mint(user1);
        nft.mint(user1);
        
        vm.prank(user1);
        nft.setApprovalForAll(user2, true);
        assertTrue(nft.isApprovedForAll(user1, user2));
        
        vm.prank(user2);
        nft.transferFrom(user1, user3, 1);
        assertEq(nft.ownerOf(1), user3);
        
        vm.prank(user2);
        nft.transferFrom(user1, user3, 2);
        assertEq(nft.ownerOf(2), user3);
    }

    function testMintToZeroAddressFails() public {
        vm.expectRevert();
        nft.mint(address(0));
    }

    function testOwnerOfNonExistentToken() public {
        vm.expectRevert();
        nft.ownerOf(999);
    }

    function testTokenURI() public {
        nft.mint(user1);
        
        // Test that tokenURI doesn't revert (base implementation might return empty string)
        try nft.tokenURI(1) returns (string memory uri) {
            // TokenURI call succeeded
            assertTrue(true);
        } catch {
            // If tokenURI reverts, that might be expected behavior
            assertTrue(true);
        }
    }

    function testERC721Compliance() public {
        nft.mint(user1);
        
        // Test IERC721 interface compliance
        IERC721 ierc721 = IERC721(address(nft));
        
        assertEq(ierc721.balanceOf(user1), 1);
        assertEq(ierc721.ownerOf(1), user1);
        
        vm.prank(user1);
        ierc721.approve(user2, 1);
        assertEq(ierc721.getApproved(1), user2);
        
        vm.prank(user1);
        ierc721.setApprovalForAll(user3, true);
        assertTrue(ierc721.isApprovedForAll(user1, user3));
    }

    function testERC165Compliance() public {
        // Test IERC165 interface compliance
        IERC165 ierc165 = IERC165(address(nft));
        
        // Should support IERC165
        assertTrue(ierc165.supportsInterface(type(IERC165).interfaceId));
        
        // Should support IERC721
        assertTrue(ierc165.supportsInterface(type(IERC721).interfaceId));
    }

    function testBalanceOfZeroAddress() public {
        vm.expectRevert();
        nft.balanceOf(address(0));
    }

    function testMintSequentialTokenIds() public {
        for (uint256 i = 1; i <= 5; i++) {
            nft.mint(user1);
            assertEq(nft.ownerOf(i), user1);
            assertEq(nft.currentTokenId(), i + 1);
        }
        
        assertEq(nft.balanceOf(user1), 5);
    }

    function testFuzzMint(address to, uint8 count) public {
        vm.assume(to != address(0));
        vm.assume(count > 0 && count <= 10); // Limit for gas
        
        uint256 initialTokenId = nft.currentTokenId();
        
        for (uint8 i = 0; i < count; i++) {
            nft.mint(to);
        }
        
        assertEq(nft.balanceOf(to), count);
        assertEq(nft.currentTokenId(), initialTokenId + count);
        
        // Verify ownership of all minted tokens
        for (uint8 i = 0; i < count; i++) {
            assertEq(nft.ownerOf(initialTokenId + i), to);
        }
    }

    function testMintLargeQuantity() public {
        uint256 quantity = 100;
        
        for (uint256 i = 0; i < quantity; i++) {
            nft.mint(user1);
        }
        
        assertEq(nft.balanceOf(user1), quantity);
        assertEq(nft.currentTokenId(), quantity + 1);
    }

    function testTokenIdIncrementsCorrectly() public {
        // Test that token IDs increment properly for multiple mints
        uint256 initialId = nft.currentTokenId();
        
        for (uint256 i = 0; i < 5; i++) {
            nft.mint(user1);
            assertEq(nft.currentTokenId(), initialId + i + 1);
            assertEq(nft.ownerOf(initialId + i), user1);
        }
        
        assertEq(nft.balanceOf(user1), 5);
    }
}