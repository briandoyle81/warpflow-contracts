import fs from "fs";
import path from "path";
import hre from "hardhat";

async function main() {
  const publicClient = await hre.viem.getPublicClient();
  const [wallet] = await hre.viem.getWalletClients();
  // Force use of chain 545 deployment directory as requested
  const chainId = 545;

  const deployDir = path.join(
    __dirname,
    "..",
    "ignition",
    "deployments",
    `chain-${chainId}`
  );
  const addressesPath = path.join(deployDir, "deployed_addresses.json");

  if (!fs.existsSync(addressesPath)) {
    console.error(
      `Deployment addresses not found for chain ${chainId} at ${addressesPath}`
    );
    process.exit(1);
  }

  const addresses = JSON.parse(fs.readFileSync(addressesPath, "utf8"));

  const shipsAddress: `0x${string}` = addresses["DeployModule#Ships"];
  if (!shipsAddress) {
    console.error("Ships address missing in deployed_addresses.json");
    process.exit(1);
  }

  console.log("Healthcheck — using addresses:", { chainId, shipsAddress });

  // Minimal liveness test: simulate claimFreeShips to ensure config.randomManager (and other deps) are set.
  try {
    await publicClient.simulateContract({
      address: shipsAddress,
      abi: (await hre.artifacts.readArtifact("Ships")).abi as any,
      functionName: "claimFreeShips",
      account: wallet.account,
    });
    console.log(
      "OK: claimFreeShips simulation succeeded (dependencies appear wired)."
    );
  } catch (err: any) {
    console.error("FAIL: claimFreeShips simulation reverted.");
    console.error(String(err?.shortMessage || err?.message || err));
    console.error(
      "Hint: ensure ships.setConfig was called on THIS instance and that randomManager/metadataRenderer/shipAttributes are non-zero."
    );
    process.exit(1);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
