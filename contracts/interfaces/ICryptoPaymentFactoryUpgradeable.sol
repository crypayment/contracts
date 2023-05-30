// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import { Types } from "../libraries/Types.sol";
import { ICryptoPaymentUpgradeable } from "./ICryptoPaymentUpgradeable.sol";

interface ICryptoPaymentFactoryUpgradeable {
    error Factory__ExecutionFailed();
    error Factory__NotAuthorized();
    error Factory__AlreadyCharged();

    function admin() external view returns (address);

    function changeAdmin(address newAdmin_) external;

    function createContract(
        bytes32 salt_,
        Types.PaymentInfo calldata paymentInfo_,
        Types.FeeInfo calldata agentInfo,
        Types.FeeInfo calldata clientInfo
    ) external;

    function claimFees(uint256 uid_, address[] calldata accounts_) external returns (uint256[] memory success);

    function distribute(ICryptoPaymentUpgradeable[] calldata instances_) external;

    function setPayment(Types.PaymentInfo calldata payment_) external;

    function setImplement(address implement_) external;

    event NewInstance(address indexed clone);
}
