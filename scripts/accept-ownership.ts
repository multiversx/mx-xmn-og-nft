import { ADMIN, DEPLOYMENT, ENV, SUI_CLIENT } from "@/env";
import { run } from "./runner";

run(async () => {
  const deployerAddress = ADMIN.getPublicKey().toSuiAddress();
  console.log(`Accepting ownership as: ${deployerAddress}`);

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

  console.log(`Network: ${ENV.DEPLOY_ON}\n`);

  try {
    const result = await SUI_CLIENT.acceptOwnership();

    console.log(`Ownership accepted successfully!`);
    console.log(`New owner: ${deployerAddress}`);
    console.log(
      `View transaction: https://suiscan.xyz/${ENV.DEPLOY_ON}/tx/${result.digest}`
    );
  } catch (error) {
    console.error(`Failed to accept ownership:`, error);
    console.log(
      "\nMake sure that ownership was transferred to this address first."
    );
    console.log("Run: npx tsx scripts/transfer-ownership.ts");
    process.exit(1);
  }
});
