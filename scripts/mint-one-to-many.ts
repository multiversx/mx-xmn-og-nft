import path from "path";
import { ADMIN, DEPLOYMENT, ENV, SUI_CLIENT } from "@/env";
import { readJSONFile, sleep } from "@/mx-bridge-typescript/src/utils";
import { run } from "./runner";

run(async () => {
  const deployerAddress = ADMIN.getPublicKey().toSuiAddress();
  console.log(`Deployer: ${deployerAddress}`);

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

  const receiversPath = path.join(path.resolve(__dirname), "../receivers.json");
  let receivers: string[];

  try {
    receivers = readJSONFile(receiversPath);
  } catch (error) {
    console.error("Error: Could not read receivers.json");
    console.log(
      "Make sure you have a receivers.json file in the project root."
    );
    process.exit(1);
  }

  if (!Array.isArray(receivers) || receivers.length === 0) {
    console.error("Error: receivers.json must be a non-empty array");
    process.exit(1);
  }

  console.log(`\nFound ${receivers.length} receiver(s) to mint to`);
  console.log(`Network: ${ENV.DEPLOY_ON}\n`);

  let successCount = 0;
  let failCount = 0;

  for (let i = 0; i < receivers.length; i++) {
    const receiver = receivers[i];

    console.log(`\n[${i + 1}/${receivers.length}] Minting to: ${receiver}`);

    try {
      const result = await SUI_CLIENT.mint(receiver);

      console.log(`Minted to ${receiver} successfully!`);
      console.log(
        `View transaction: https://suiscan.xyz/${ENV.DEPLOY_ON}/tx/${result.digest}`
      );
      successCount++;

      if (i < receivers.length - 1) {
        await sleep(2000);
      }
    } catch (error) {
      console.error(`Failed:`, error);
      failCount++;
    }
  }

  console.log("\nMINTING COMPLETE");
  console.log(`Total: ${receivers.length}`);
  console.log(`Success: ${successCount}`);
  console.log(`Failed: ${failCount}`);
});
