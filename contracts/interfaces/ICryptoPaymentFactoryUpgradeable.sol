// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import { Types } from "../libraries/Types.sol";

interface ICryptoPaymentFactoryUpgradeable {
    error Factory__ExecutionFailed();
    error Factory__NotAuthorized();
    error Factory__AlreadyCharged();

    function admin() external view returns (address);

    function changeAdmin(address newAdmin_) external;

    function setImplement(address implement_) external;

    function createContract(
        bytes32 salt_,
        Types.PaymentInfo calldata paymentInfo_,
        Types.FeeInfo calldata agentInfo,
        Types.FeeInfo calldata clientInfo
    ) external;

    event NewInstance(address indexed clone);
    event Claimed(address indexed sender, uint256[] success);
}
