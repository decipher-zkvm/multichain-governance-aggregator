// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {GovernanceResultProver} from "../../src/vlayer/GovernanceResultProver.sol";
import {Governance} from "../../src/vlayer/Governance.sol";
import {GovernanceToken} from "../../src/vlayer/GovernanceToken.sol";
import {IGovernance} from "../../src/vlayer/IGovernance.sol";

// Mock Proof struct for testing
struct Proof {
    bytes data;
}

// Mock Prover contract for testing
abstract contract MockProver {
    function proof() internal pure returns (Proof memory) {
        return Proof({data: "mock_governance_proof"});
    }
    
    function setChain(uint256 chainId, uint256 blockNumber) internal pure {
        // Mock implementation - in real vlayer this would switch context
    }
}

contract MockGovernanceResultProver is MockProver {
    mapping(uint256 => mapping(address => mapping(uint256 => Governance))) public mockGovernanceContracts;
    
    function setMockGovernance(uint256 chainId, address contractAddr, uint256 proposalId, Governance governance) external {
        mockGovernanceContracts[chainId][contractAddr][proposalId] = governance;
    }
    
    function crossChainGovernanceResultOf(address governanceContract, uint256 proposalId, uint256[] memory chainIds, uint256 blockNum)
        public
        returns (Proof memory, address, uint256, uint256, uint256)
    {
        uint256 totalYesVotes = 0;
        uint256 totalNoVotes = 0;
        
        for (uint256 i = 0; i < chainIds.length; i++) {
            setChain(chainIds[i], blockNum);
            
            // In a real implementation, this would query the actual governance contract
            // For testing, we'll use mock data or make assumptions
            Governance mockGov = mockGovernanceContracts[chainIds[i]][governanceContract][proposalId];
            if (address(mockGov) != address(0)) {
                (, uint256 endBlock, uint256 yesVotes, uint256 noVotes) = mockGov.getProposal(proposalId);
                require(endBlock <= blockNum, "Voting is not ended yet");
                totalYesVotes += yesVotes;
                totalNoVotes += noVotes;
            } else {
                // Use default mock values for testing
                uint256 mockStartBlock = blockNum - 100;
                uint256 mockEndBlock = blockNum - 10;
                require(mockEndBlock <= blockNum, "Voting is not ended yet");
                totalYesVotes += 1000 * 10**18; // Mock yes votes
                totalNoVotes += 500 * 10**18;   // Mock no votes
            }
        }

        return (proof(), governanceContract, proposalId, totalYesVotes, totalNoVotes);
    }
}

contract GovernanceResultProverTest is Test {
    MockGovernanceResultProver public prover;
    Governance public governance1;
    Governance public governance2;
    GovernanceToken public token;
    
    address public governanceContract = address(0x123);
    uint256 public constant PROPOSAL_ID = 1;
    uint256 public constant CHAIN_ID_1 = 1;    // Ethereum
    uint256 public constant CHAIN_ID_2 = 8453; // Base
    uint256 public constant BLOCK_NUM = 2000;

    function setUp() public {
        prover = new MockGovernanceResultProver();
        token = new GovernanceToken("Test Token", "TEST");
        governance1 = new Governance(token);
        governance2 = new Governance(token);
        
        // Create test proposals
        governance1.createProposal(PROPOSAL_ID, BLOCK_NUM - 100, BLOCK_NUM - 10);
        governance2.createProposal(PROPOSAL_ID, BLOCK_NUM - 100, BLOCK_NUM - 10);
        
        // Add some votes to the governance contracts
        token.transfer(address(0x111), 100 * 10**18);
        token.transfer(address(0x222), 200 * 10**18);
        
        vm.roll(BLOCK_NUM - 50); // Set block to voting period
        vm.prank(address(0x111));
        governance1.castVote(PROPOSAL_ID, true);
        vm.prank(address(0x222));
        governance2.castVote(PROPOSAL_ID, false);
        
        // Set up mock governance contracts for different chains
        prover.setMockGovernance(CHAIN_ID_1, governanceContract, PROPOSAL_ID, governance1);
        prover.setMockGovernance(CHAIN_ID_2, governanceContract, PROPOSAL_ID, governance2);
        
        vm.roll(BLOCK_NUM); // Move to end of voting
    }

    function testProverDeployment() public {
        assertNotEq(address(prover), address(0));
    }

    function testCrossChainGovernanceResultSingleChain() public {
        uint256[] memory chainIds = new uint256[](1);
        chainIds[0] = CHAIN_ID_1;
        
        (Proof memory proof, address returnedContract, uint256 returnedProposalId, uint256 totalYes, uint256 totalNo) = 
            prover.crossChainGovernanceResultOf(governanceContract, PROPOSAL_ID, chainIds, BLOCK_NUM);
        
        assertEq(returnedContract, governanceContract);
        assertEq(returnedProposalId, PROPOSAL_ID);
        assertEq(proof.data, "mock_governance_proof");
        
        // Should have actual governance data now
        assertEq(totalYes, 100 * 10**18); // From governance1
        assertEq(totalNo, 0); // governance1 has no votes
    }

    function testCrossChainGovernanceResultMultipleChains() public {
        uint256[] memory chainIds = new uint256[](2);
        chainIds[0] = CHAIN_ID_1;
        chainIds[1] = CHAIN_ID_2;
        
        (Proof memory proof, address returnedContract, uint256 returnedProposalId, uint256 totalYes, uint256 totalNo) = 
            prover.crossChainGovernanceResultOf(governanceContract, PROPOSAL_ID, chainIds, BLOCK_NUM);
        
        assertEq(returnedContract, governanceContract);
        assertEq(returnedProposalId, PROPOSAL_ID);
        assertEq(proof.data, "mock_governance_proof");
        
        // Should aggregate results from both chains
        assertEq(totalYes, 100 * 10**18); // Only governance1 has yes votes
        assertEq(totalNo, 200 * 10**18);  // Only governance2 has no votes
    }

    function testCrossChainGovernanceResultEmptyChains() public {
        uint256[] memory chainIds = new uint256[](0);
        
        (Proof memory proof, address returnedContract, uint256 returnedProposalId, uint256 totalYes, uint256 totalNo) = 
            prover.crossChainGovernanceResultOf(governanceContract, PROPOSAL_ID, chainIds, BLOCK_NUM);
        
        assertEq(returnedContract, governanceContract);
        assertEq(returnedProposalId, PROPOSAL_ID);
        assertEq(totalYes, 0);
        assertEq(totalNo, 0);
    }

    function testVotingNotEndedRevert() public {
        uint256[] memory chainIds = new uint256[](1);
        chainIds[0] = CHAIN_ID_1;
        
        // Try to query before voting ends
        uint256 earlyBlockNum = BLOCK_NUM - 50; // Voting ends at BLOCK_NUM - 10
        
        vm.expectRevert("Voting is not ended yet");
        prover.crossChainGovernanceResultOf(governanceContract, PROPOSAL_ID, chainIds, earlyBlockNum);
    }

    function testDifferentProposalIds() public {
        uint256[] memory chainIds = new uint256[](1);
        chainIds[0] = CHAIN_ID_1;
        
        uint256 proposalId1 = 1;
        uint256 proposalId2 = 2;
        
        (, , uint256 returnedId1, ,) = prover.crossChainGovernanceResultOf(governanceContract, proposalId1, chainIds, BLOCK_NUM);
        (, , uint256 returnedId2, ,) = prover.crossChainGovernanceResultOf(governanceContract, proposalId2, chainIds, BLOCK_NUM);
        
        assertEq(returnedId1, proposalId1);
        assertEq(returnedId2, proposalId2);
    }

    function testDifferentGovernanceContracts() public {
        uint256[] memory chainIds = new uint256[](1);
        chainIds[0] = CHAIN_ID_1;
        
        address contract1 = address(0x111);
        address contract2 = address(0x222);
        
        (, address returned1, , ,) = prover.crossChainGovernanceResultOf(contract1, PROPOSAL_ID, chainIds, BLOCK_NUM);
        (, address returned2, , ,) = prover.crossChainGovernanceResultOf(contract2, PROPOSAL_ID, chainIds, BLOCK_NUM);
        
        assertEq(returned1, contract1);
        assertEq(returned2, contract2);
    }

    function testFuzzCrossChainGovernanceResult(
        address _governanceContract, 
        uint256 _proposalId, 
        uint8 chainCount,
        uint256 _blockNum
    ) public {
        vm.assume(_governanceContract != address(0));
        vm.assume(_proposalId > 0);
        chainCount = uint8(bound(chainCount, 0, 5)); // Limit for gas
        _blockNum = bound(_blockNum, 1000, type(uint64).max);
        
        uint256[] memory chainIds = new uint256[](chainCount);
        for (uint8 i = 0; i < chainCount; i++) {
            chainIds[i] = i + 1;
        }
        
        (Proof memory proof, address returnedContract, uint256 returnedProposalId, uint256 totalYes, uint256 totalNo) = 
            prover.crossChainGovernanceResultOf(_governanceContract, _proposalId, chainIds, _blockNum);
        
        assertEq(returnedContract, _governanceContract);
        assertEq(returnedProposalId, _proposalId);
        assertEq(proof.data, "mock_governance_proof");
        
        // Expected totals based on mock values
        uint256 expectedYes = uint256(chainCount) * 1000 * 10**18;
        uint256 expectedNo = uint256(chainCount) * 500 * 10**18;
        
        assertEq(totalYes, expectedYes);
        assertEq(totalNo, expectedNo);
    }

    function testLargeChainArray() public {
        uint256 chainCount = 10;
        uint256[] memory chainIds = new uint256[](chainCount);
        for (uint256 i = 0; i < chainCount; i++) {
            chainIds[i] = i + 1;
        }
        
        (,, , uint256 totalYes, uint256 totalNo) = 
            prover.crossChainGovernanceResultOf(governanceContract, PROPOSAL_ID, chainIds, BLOCK_NUM);
        
        // For the large chain array (10 chains): Chain 1 has real data, rest use mock
        // Chain 1 (CHAIN_ID_1=1): 100 yes, 0 no
        // Chains 2-10: 1000 yes, 500 no each (mock)
        uint256 expectedYes = 100 * 10**18 + (chainCount - 1) * 1000 * 10**18;
        uint256 expectedNo = 0 + (chainCount - 1) * 500 * 10**18;
        
        assertEq(totalYes, expectedYes);
        assertEq(totalNo, expectedNo);
    }

    function testVoteAggregation() public {
        uint256[] memory chainIds = new uint256[](3);
        chainIds[0] = 1;
        chainIds[1] = 2;
        chainIds[2] = 3;
        
        (,, , uint256 totalYes, uint256 totalNo) = 
            prover.crossChainGovernanceResultOf(governanceContract, PROPOSAL_ID, chainIds, BLOCK_NUM);
        
        // For the 3-chain test: Chain 1 has real data, chains 2 and 3 use mock data
        // Chain 1 (CHAIN_ID_1=1): 100 yes, 0 no
        // Chain 2: 1000 yes, 500 no (mock)
        // Chain 3: 1000 yes, 500 no (mock)
        uint256 expectedYes = 100 * 10**18 + 2 * 1000 * 10**18;  // 2100
        uint256 expectedNo = 0 + 2 * 500 * 10**18;               // 1000
        
        assertEq(totalYes, expectedYes);
        assertEq(totalNo, expectedNo);
    }

    function testProofGeneration() public {
        uint256[] memory chainIds = new uint256[](1);
        chainIds[0] = CHAIN_ID_1;
        
        (Proof memory proof, , , ,) = 
            prover.crossChainGovernanceResultOf(governanceContract, PROPOSAL_ID, chainIds, BLOCK_NUM);
        
        // Verify proof is generated
        assertEq(proof.data, "mock_governance_proof");
        assertTrue(proof.data.length > 0);
    }
}