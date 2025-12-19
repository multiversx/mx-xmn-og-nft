export function run(fn: () => Promise<any>) {
  fn()
    .then(() => {
      console.log("Script completed successfully.");
      process.exit(0);
    })
    .catch((error) => {
      console.error("Error:", error);
      process.exit(1);
    });
}
