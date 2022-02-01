import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect, assert } from "chai";
import { BigNumber } from "ethers";
import { ethers, run } from "hardhat";
import { Claimer, Minter } from "../typechain"


describe("C2C", function () {
  before(async function() {
    await run("deploy", { "tags": "C2C" });
  })

  it("Should perform a deposit", async function () {
    const claimer = <Claimer>await ethers.getContract('Claimer')
    const minter = <Minter>await ethers.getContract('Minter')
    assert(false, "Not implemented")
  });

  it("Should perform a withdrawal", async function () {
    assert(false, "Not implemented")
  });
});
