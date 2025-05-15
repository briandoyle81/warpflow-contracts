import { createWalletClient, http, parseGwei } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { flowTestnet } from "viem/chains";
import dotenv from "dotenv";

dotenv.config();

// Get the private key from env and add the 0x prefix
const rawKey = process.env.METAMASK_WALLET_1;

if (!rawKey || rawKey.length !== 64) {
  throw new Error(
    `Invalid private key in .env: must be 64 hex characters (no 0x). Got: ${rawKey?.length} characters.`
  );
}

const privateKey = `0x${rawKey}` as `0x${string}`;
const account = privateKeyToAccount(privateKey);

const client = createWalletClient({
  account,
  chain: flowTestnet,
  transport: http(), // customize if needed
});

async function sendNoOpTransaction() {
  const nonce = 818;
  const txHash = await client.sendTransaction({
    to: account.address,
    value: 0n,
    nonce,
    gas: 21000n,
    maxFeePerGas: parseGwei("1"),
    maxPriorityFeePerGas: parseGwei("1"),
  });

  console.log("✅ Sent no-op tx with hash:", txHash);
}

sendNoOpTransaction().catch(console.error);
