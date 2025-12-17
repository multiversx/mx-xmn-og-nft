import { ADMIN, DEPLOYMENT, ENV, SUI_CLIENT } from "@/env";

/// --- PARAMS ---
const NEW_OWNER =
  "0x69051698845a1beea0472a234f073fad981e4db72b6690c0970a902e6f548524";
/// --------------

async function main() {
  const deployerAddress = ADMIN.getPublicKey().toSuiAddress();
  console.log(`Current owner: ${deployerAddress}`);

  if (!DEPLOYMENT.Package) {
    console.error("Error: No active deployment found");
    console.log(
      "Make sure you have deployed the package first and have an active deployment."
    );
    console.log("\nTo deploy: npx tsx scripts/deploy.ts");
    console.log(
      "To set active deployment: DEPLOYMENT_ID=<id> npx tsx scripts/mark-active.ts"
    );
    process.exit(1);
  }

  if (!NEW_OWNER) {
    process.exit(1);
  }

  console.log(`\nTransferring ownership to: ${NEW_OWNER}`);
  console.log(`Network: ${ENV.DEPLOY_ON}\n`);

  try {
    const result = await SUI_CLIENT.transferOwnership(NEW_OWNER);
    console.log(`Ownership transfer initiated successfully!`);
    console.log("TX Digest:", result.digest);
    console.log(
      `View transaction: https://suiscan.xyz/${ENV.DEPLOY_ON}/tx/${result.digest}`
    );
    console.log(
      `\nThe new owner (${NEW_OWNER}) must now accept ownership by running:`
    );
    console.log(`npx tsx scripts/accept-ownership.ts`);
  } catch (error) {
    console.error(`Failed to transfer ownership:`, error);
    process.exit(1);
  }
}

if (require.main === module) {
  main().catch((error) => {
    console.error("Error:", error);
    process.exit(1);
  });
}
