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
  const USDC = "0x3AfB052aD80637a3e979a935Bd784e3E07D258d3";
  const admin = "0xb204A17dc1c462bbbEd44Ade9D58721568bE7115";
  const operators = [admin];
  const servers = [admin];
  const name = "RoleManager";
  const version = "1";
  const threshold = 2;
  const payment = [USDC, 10 * 50 ** 6];

  const roleManager = await deployAndVerify(
    "RoleManagerUpgradeable",
    [admin, operators, servers, name, version, threshold],
    true,
    "contracts/RoleManagerUpgradeable.sol:RoleManagerUpgradeable",
    {
      kind: "uups",
      initializer: "initialize",
    },
  );

  const instance = await deployAndVerify("CryptoPayment", [], true, "contracts/CryptoPayment.sol:CryptoPayment");
  await deployAndVerify(
    "CryptoPaymentFactoryUpgradeable",
    [instance.address, roleManager.address, payment],
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
