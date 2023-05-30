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
  const USDC = "0xB33B3237f00C5803e135ACa5eCB9e11668957Ab9";
  const admin = "0xb204A17dc1c462bbbEd44Ade9D58721568bE7115";
  const payment = [USDC, 10 * 50 ** 6];
  // original
  const instance = await deployAndVerify("CryptoPayment", [], true, "contracts/CryptoPayment.sol:CryptoPayment");
  await deployAndVerify(
    "CryptoPaymentFactoryUpgradeable",
    [instance.address, admin, admin, admin, payment],
    true,
    "contracts/CryptoPaymentFactoryUpgradeable.sol:CryptoPaymentFactoryUpgradeable",
    {
      kind: "uups",
      initializer: "initialize",
    },
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
