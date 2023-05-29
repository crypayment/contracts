import { DeployProxyOptions } from "@openzeppelin/hardhat-upgrades/dist/utils";
import * as dotenv from "dotenv";
import { Contract, ContractFactory } from "ethers";
import { ethers, run, upgrades } from "hardhat";

dotenv.config();

const deployAndVerify = async (
  name: string,
  params: unknown[],
  canVerify: boolean = true,
  path?: string | undefined,
  proxyOptions?: DeployProxyOptions | undefined,
): Promise<Contract> => {
  const Factory: ContractFactory = await ethers.getContractFactory(name);
  const instance: Contract = proxyOptions
    ? await upgrades.deployProxy(Factory, params, proxyOptions)
    : await Factory.deploy(...params);
  await instance.deployed();

  if (canVerify)
    await run(`verify:verify`, {
      contract: path,
      address: instance.address,
      constructorArguments: proxyOptions ? [] : params,
    });

  console.log(`${name} deployed at: ${instance.address}`);

  return instance;
};

async function main() {
  // original
  await deployAndVerify("CryptoPayment", [], true, "contracts/CryptoPayment.sol:CryptoPayment");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
