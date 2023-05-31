import { ContractAddressOrInstance } from "@openzeppelin/hardhat-upgrades/dist/utils/contract-types";
import * as dotenv from "dotenv";
import { Contract, ContractFactory } from "ethers";
import { ethers, upgrades } from "hardhat";

dotenv.config();

async function main(): Promise<void> {
  const CPU: ContractFactory = await ethers.getContractFactory("CryptoPaymentUpgradeable");

  const beaconImplement: Contract = await upgrades.deployBeacon(CPU);
  await beaconImplement.deployed();

  console.log(`Beacon implement deployed at: ${beaconImplement.address}`);
  const implementAddress: ContractAddressOrInstance = beaconImplement.address;

  const beaconProxy: Contract = await upgrades.deployBeaconProxy(implementAddress, CPU, [
    ["0xB33B3237f00C5803e135ACa5eCB9e11668957Ab9", 0],
    [ethers.constants.AddressZero, 0],
    [ethers.constants.AddressZero, 0],
    [ethers.constants.AddressZero, 0],
  ]);
  await beaconProxy.deployed();
  console.log(`Proxy deployed at ${beaconProxy.address}`);
}

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });
