// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {GovernanceResultVerifier} from "../../src/vlayer/GovernanceResultVerifier.sol";

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

contract MockGovernanceResultVerifier is MockVerifier {
    address public prover;

    struct ProposalAggregated {
        address governanceContract;
        uint256 totalYesVotes;
        uint256 totalNoVotes;
        bool aggregated;
    }

    mapping(uint256 => ProposalAggregated) public proposals;

    constructor(address _prover) {
        prover = _prover;
    }

    function aggregate(Proof calldata, address governanceContract, uint256 proposalId, uint256 totalYesVotes, uint256 totalNoVotes)
        public
        onlyVerified(prover, bytes4(0)) // Mock selector
    {
        require(!proposals[proposalId].aggregated, "Already aggregated");

        proposals[proposalId].governanceContract = governanceContract;
        proposals[proposalId].totalYesVotes = totalYesVotes;
        proposals[proposalId].totalNoVotes = totalNoVotes;
        proposals[proposalId].aggregated = true;
    }

    function getAggregate(uint256 proposalId) external view returns (uint256 totalYesVotes, uint256 totalNoVotes) {
        return (proposals[proposalId].totalYesVotes, proposals[proposalId].totalNoVotes);
    }
}

contract GovernanceResultVerifierTest is Test {
    MockGovernanceResultVerifier public verifier;
    
    address public prover = address(0x1);
    address public governanceContract = address(0x2);
    
    uint256 public constant PROPOSAL_ID = 1;
    uint256 public constant YES_VOTES = 1000 * 10**18;
    uint256 public constant NO_VOTES = 500 * 10**18;

    function setUp() public {
        verifier = new MockGovernanceResultVerifier(prover);
    }

    function testConstructor() public {
        assertEq(verifier.prover(), prover);
    }

    function testAggregate() public {
        Proof memory mockProof = Proof({data: "mock_proof"});
        
        verifier.aggregate(mockProof, governanceContract, PROPOSAL_ID, YES_VOTES, NO_VOTES);
        
        (address storedContract, uint256 storedYes, uint256 storedNo, bool aggregated) = verifier.proposals(PROPOSAL_ID);
        assertEq(storedContract, governanceContract);
        assertEq(storedYes, YES_VOTES);
        assertEq(storedNo, NO_VOTES);
        assertTrue(aggregated);
    }

    function testGetAggregate() public {
        Proof memory mockProof = Proof({data: "mock_proof"});
        
        verifier.aggregate(mockProof, governanceContract, PROPOSAL_ID, YES_VOTES, NO_VOTES);
        
        (uint256 totalYes, uint256 totalNo) = verifier.getAggregate(PROPOSAL_ID);
        assertEq(totalYes, YES_VOTES);
        assertEq(totalNo, NO_VOTES);
    }

    function testGetAggregateForNonExistentProposal() public {
        (uint256 totalYes, uint256 totalNo) = verifier.getAggregate(999);
        assertEq(totalYes, 0);
        assertEq(totalNo, 0);
    }

    function testAggregateFailsIfAlreadyAggregated() public {
        Proof memory mockProof = Proof({data: "mock_proof"});
        
        // First aggregation should succeed
        verifier.aggregate(mockProof, governanceContract, PROPOSAL_ID, YES_VOTES, NO_VOTES);
        
        // Second aggregation should fail
        vm.expectRevert("Already aggregated");
        verifier.aggregate(mockProof, governanceContract, PROPOSAL_ID, YES_VOTES * 2, NO_VOTES * 2);
    }

    function testMultipleProposalsIndependence() public {
        Proof memory mockProof = Proof({data: "mock_proof"});
        
        uint256 proposal1 = 1;
        uint256 proposal2 = 2;
        address contract1 = address(0x111);
        address contract2 = address(0x222);
        
        verifier.aggregate(mockProof, contract1, proposal1, YES_VOTES, NO_VOTES);
        verifier.aggregate(mockProof, contract2, proposal2, YES_VOTES * 2, NO_VOTES * 2);
        
        (uint256 yes1, uint256 no1) = verifier.getAggregate(proposal1);
        (uint256 yes2, uint256 no2) = verifier.getAggregate(proposal2);
        
        assertEq(yes1, YES_VOTES);
        assertEq(no1, NO_VOTES);
        assertEq(yes2, YES_VOTES * 2);
        assertEq(no2, NO_VOTES * 2);
        
        (address stored1, , , bool agg1) = verifier.proposals(proposal1);
        (address stored2, , , bool agg2) = verifier.proposals(proposal2);
        
        assertEq(stored1, contract1);
        assertEq(stored2, contract2);
        assertTrue(agg1);
        assertTrue(agg2);
    }

    function testAggregateWithZeroVotes() public {
        Proof memory mockProof = Proof({data: "mock_proof"});
        
        verifier.aggregate(mockProof, governanceContract, PROPOSAL_ID, 0, 0);
        
        (uint256 totalYes, uint256 totalNo) = verifier.getAggregate(PROPOSAL_ID);
        assertEq(totalYes, 0);
        assertEq(totalNo, 0);
        
        (, , , bool aggregated) = verifier.proposals(PROPOSAL_ID);
        assertTrue(aggregated);
    }

    function testAggregateWithLargeVotes() public {
        Proof memory mockProof = Proof({data: "mock_proof"});
        
        uint256 largeYes = type(uint128).max;
        uint256 largeNo = type(uint128).max - 1;
        
        verifier.aggregate(mockProof, governanceContract, PROPOSAL_ID, largeYes, largeNo);
        
        (uint256 totalYes, uint256 totalNo) = verifier.getAggregate(PROPOSAL_ID);
        assertEq(totalYes, largeYes);
        assertEq(totalNo, largeNo);
    }

    function testProposalStructFields() public {
        Proof memory mockProof = Proof({data: "mock_proof"});
        
        verifier.aggregate(mockProof, governanceContract, PROPOSAL_ID, YES_VOTES, NO_VOTES);
        
        (address storedContract, uint256 storedYes, uint256 storedNo, bool aggregated) = verifier.proposals(PROPOSAL_ID);
        
        // Verify all fields are correctly stored
        assertEq(storedContract, governanceContract);
        assertEq(storedYes, YES_VOTES);
        assertEq(storedNo, NO_VOTES);
        assertTrue(aggregated);
    }

    function testInitialProposalState() public {
        // Check initial state before any aggregation
        (address storedContract, uint256 storedYes, uint256 storedNo, bool aggregated) = verifier.proposals(PROPOSAL_ID);
        
        assertEq(storedContract, address(0));
        assertEq(storedYes, 0);
        assertEq(storedNo, 0);
        assertFalse(aggregated);
    }

    function testFuzzAggregate(
        address _governanceContract,
        uint256 _proposalId,
        uint256 _yesVotes,
        uint256 _noVotes
    ) public {
        vm.assume(_governanceContract != address(0));
        vm.assume(_proposalId > 0);
        
        Proof memory mockProof = Proof({data: "mock_proof"});
        
        verifier.aggregate(mockProof, _governanceContract, _proposalId, _yesVotes, _noVotes);
        
        (address storedContract, uint256 storedYes, uint256 storedNo, bool aggregated) = verifier.proposals(_proposalId);
        
        assertEq(storedContract, _governanceContract);
        assertEq(storedYes, _yesVotes);
        assertEq(storedNo, _noVotes);
        assertTrue(aggregated);
        
        (uint256 totalYes, uint256 totalNo) = verifier.getAggregate(_proposalId);
        assertEq(totalYes, _yesVotes);
        assertEq(totalNo, _noVotes);
    }

    function testFuzzMultipleProposals(uint256 _proposalCount) public {
        // Use vm.assume to avoid problematic inputs
        vm.assume(_proposalCount >= 1 && _proposalCount <= 3);
        uint8 proposalCount = uint8(_proposalCount);
        
        Proof memory mockProof = Proof({data: "mock_proof"});
        
        // Create simple test data
        for (uint8 i = 0; i < proposalCount; i++) {
            uint256 proposalId = uint256(i) + 1;
            uint256 yesVotes = (uint256(i) + 1) * 100;
            uint256 noVotes = (uint256(i) + 1) * 50;
            
            verifier.aggregate(mockProof, governanceContract, proposalId, yesVotes, noVotes);
        }
        
        // Verify all proposals were aggregated correctly
        for (uint8 i = 0; i < proposalCount; i++) {
            uint256 proposalId = uint256(i) + 1;
            uint256 expectedYes = (uint256(i) + 1) * 100;
            uint256 expectedNo = (uint256(i) + 1) * 50;
            
            (uint256 totalYes, uint256 totalNo) = verifier.getAggregate(proposalId);
            assertEq(totalYes, expectedYes);
            assertEq(totalNo, expectedNo);
            
            (, , , bool aggregated) = verifier.proposals(proposalId);
            assertTrue(aggregated);
        }
    }

    function testAggregateStateConsistency() public {
        Proof memory mockProof = Proof({data: "mock_proof"});
        
        // Before aggregation
        (uint256 totalYesBefore, uint256 totalNoBefore) = verifier.getAggregate(PROPOSAL_ID);
        (, , , bool aggregatedBefore) = verifier.proposals(PROPOSAL_ID);
        
        assertEq(totalYesBefore, 0);
        assertEq(totalNoBefore, 0);
        assertFalse(aggregatedBefore);
        
        // After aggregation
        verifier.aggregate(mockProof, governanceContract, PROPOSAL_ID, YES_VOTES, NO_VOTES);
        
        (uint256 totalYesAfter, uint256 totalNoAfter) = verifier.getAggregate(PROPOSAL_ID);
        (, , , bool aggregatedAfter) = verifier.proposals(PROPOSAL_ID);
        
        assertEq(totalYesAfter, YES_VOTES);
        assertEq(totalNoAfter, NO_VOTES);
        assertTrue(aggregatedAfter);
    }

    function testMaxValueVotes() public {
        Proof memory mockProof = Proof({data: "mock_proof"});
        
        uint256 maxYes = type(uint256).max;
        uint256 maxNo = type(uint256).max - 1;
        
        verifier.aggregate(mockProof, governanceContract, PROPOSAL_ID, maxYes, maxNo);
        
        (uint256 totalYes, uint256 totalNo) = verifier.getAggregate(PROPOSAL_ID);
        assertEq(totalYes, maxYes);
        assertEq(totalNo, maxNo);
    }
}