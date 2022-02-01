// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers, deployments } from "hardhat";
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const getExpectedAddr = async (signer: SignerWithAddress) => {
  const nonce = await signer.getTransactionCount()
  return ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(
      [ "address", "uint256" ],
      [ signer.address, nonce ]
  )).slice(0, 42)
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const [ l1Deployer, l2Deployer ] = await ethers.getSigners()

  const l1 = await deployments.deploy("Claimer", {
    from: l1Deployer.address,
    args: [await getExpectedAddr(l2Deployer)]
  })

  const l2 = await deployments.deploy("Minter", {
    from: l2Deployer.address,
    args: [l1.address]
  })

  console.log("L1 deployed to:", l1.address);
  console.log("L2 deployed to:", l2.address);
};

export default func;
func.tags = ['C2C'];
