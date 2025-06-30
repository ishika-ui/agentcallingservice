const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  const agent = "0xAgentAddress"; // Replace
  const client = deployer.address;
  const duration = 3600; // 1 hour
  const amount = hre.ethers.utils.parseEther("0.01");

  const SafeServiceEscrow = await hre.ethers.getContractFactory("SafeServiceEscrow");
  const escrow = await SafeServiceEscrow.deploy(client, agent, duration, { value: amount });

  await escrow.deployed();
  console.log(`Escrow deployed to: ${escrow.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
