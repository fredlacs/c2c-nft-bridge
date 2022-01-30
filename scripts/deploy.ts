// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";

const getExpectedAddr = async (signer: SignerWithAddress) => {
  const nonce = await signer.getTransactionCount()
  return ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(
      [ "address", "uint256" ],
      [ signer.address, nonce ]
  ))
}

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const [ l1Deployer, l2Deployer ] = await ethers.getSigners()

  const L1 = await (await ethers.getContractFactory("L1")).connect(l1Deployer);
  const l1 = await L1.deploy(await getExpectedAddr(l2Deployer));
  await l1.deployed();

  const L2 = await (await ethers.getContractFactory("L2")).connect(l2Deployer);
  const l2 = await L2.deploy(l1.address);
  await l2.deployed();

  console.log("L1 deployed to:", l1.address);
  console.log("L2 deployed to:", l2.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
