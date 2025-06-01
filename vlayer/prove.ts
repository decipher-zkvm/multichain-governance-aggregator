import { createVlayerClient } from "@vlayer/sdk"
import proverSpec from "../out/GovernanceResultProver.sol/GovernanceResultProver"
import verifierSpec from "../out/GovernanceResultVerifier.sol/GovernanceResultVerifier"
import governanceSpec from "../out/Governance.sol/Governance"
import {
    createContext,
    deployVlayerContracts,
    getConfig,
    waitForContractDeploy
} from "@vlayer/sdk/config"
import { type Address } from "viem"
import { loadFixtures } from "./loadFixtures"
import { getTeleportConfig } from "./constants"

console.log("Starting proof generation...")

const config = getConfig()
// const teleportConfig = getTeleportConfig(config.chainName)

const governanceTeleportConfig = {
    governanceContract: "0x7Fa1a39FC8F2CE1DB862ac2c127bbd1dBacD62B7",
    proposalId: 1,
    chainIds: [11155420],
    blockNumber: 28189336
}

if (config.chainName === "anvil") {
    await loadFixtures()
}

const { chain, ethClient, account, proverUrl, confirmations } =
    createContext(config)

if (!account) {
    throw new Error(
        "No account found make sure EXAMPLES_TEST_PRIVATE_KEY is set in your environment variables"
    )
}
const vlayer = createVlayerClient({
    url: proverUrl,
    token: config.token
})

console.log("Vlayer client created")

const { prover, verifier } = await deployVlayerContracts({
    proverSpec,
    verifierSpec,
    proverArgs: [],
    verifierArgs: []
})

console.log("Prover:", prover)
console.log("Verifier:", verifier)

// TODO: deploy governance aggregator

const proofHash = await vlayer.prove({
    address: prover,
    proverAbi: proverSpec.abi,
    functionName: "crossChainGovernanceResultOf",
    args: [
        governanceTeleportConfig.governanceContract,
        governanceTeleportConfig.proposalId,
        governanceTeleportConfig.chainIds,
        governanceTeleportConfig.blockNumber
    ],
    chainId: chain.id,
    gasLimit: config.gasLimit
})
const result = await vlayer.waitForProvingResult({ hash: proofHash })
console.log("Proof:", result[0])
console.log("⏳ Verifying...")

// Workaround for viem estimating gas with `latest` block causing future block assumptions to fail on slower chains like mainnet/sepolia
const gas = await ethClient.estimateContractGas({
    address: verifier,
    abi: verifierSpec.abi,
    functionName: "aggregate",
    args: result,
    account,
    blockTag: "pending"
})

const verificationHash = await ethClient.writeContract({
    address: verifier,
    abi: verifierSpec.abi,
    functionName: "aggregate",
    args: result,
    account,
    gas
})

const receipt = await ethClient.waitForTransactionReceipt({
    hash: verificationHash,
    confirmations,
    retryCount: 60,
    retryDelay: 1000
})

console.log(`✅ Verification result: ${receipt.status}`)

const { totalYesVotes, totalNoVotes } = await ethClient.readContract({
    address: verifier,
    abi: verifierSpec.abi,
    functionName: "getAggregate",
    args: [governanceTeleportConfig.proposalId]
})

console.log("Total yes votes:", totalYesVotes)
console.log("Total no votes:", totalNoVotes)
