// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { AccessControlEnumerableUpgradeable } from "./internal-upgradeable/AccessControlEnumerableUpgradeable.sol";
import { ClaimFeeUpgradeable } from "./internal-upgradeable/ClaimFeeUpgradeable.sol";
import { FactoryUpgradeable } from "./internal-upgradeable/FactoryUpgradeable.sol";
import { PaymentUpgradeable } from "./internal-upgradeable/PaymentUpgradeable.sol";

import { ICryptoPaymentUpgradeable } from "./interfaces/ICryptoPaymentUpgradeable.sol";
import { ICryptoPaymentFactoryUpgradeable } from "./interfaces/ICryptoPaymentFactoryUpgradeable.sol";

import { ErrorHandler } from "./libraries/ErrorHandler.sol";
import { Types } from "./libraries/Types.sol";
import { HUNDER_PERCENT, OPERATOR_ROLE, SERVER_ROLE, UPGRADER_ROLE } from "./libraries/Constants.sol";

contract CryptoPaymentFactoryUpgradeable is
    ICryptoPaymentFactoryUpgradeable,
    Initializable,
    UUPSUpgradeable,
    AccessControlEnumerableUpgradeable,
    ClaimFeeUpgradeable,
    FactoryUpgradeable,
    PaymentUpgradeable
{
    using ErrorHandler for bool;

    bytes4 private constant INITIALIZE_SELECTOR = 0x1cd8a2e0;

    mapping(bytes32 => Types.CloneInfo) public instance;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address implement_,
        address admin_,
        address operator_,
        address server_,
        Types.PaymentInfo calldata payment_
    ) external initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __Factory_init_unchained(implement_);
        __Payment_init(payment_);

        bytes32 operatorRole = OPERATOR_ROLE;
        _grantRole(operatorRole, operator_);
        _grantRole(operatorRole, admin_);
        _grantRole(SERVER_ROLE, server_);
        _grantRole(UPGRADER_ROLE, admin_);
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
    }

    function createContract(
        bytes32 salt_,
        Types.PaymentInfo calldata paymentInfo_,
        Types.FeeInfo calldata clientInfo,
        Types.FeeInfo calldata agentInfo
    ) external override onlyRole(OPERATOR_ROLE) {
        Types.FeeInfo memory adminInfo = Types.FeeInfo(
            admin(),
            HUNDER_PERCENT - clientInfo.percentage - agentInfo.percentage
        );

        address clone = _cheapClone(
            salt_,
            INITIALIZE_SELECTOR,
            abi.encode(paymentInfo_, adminInfo, clientInfo, agentInfo)
        );
        instance[salt_] = Types.CloneInfo(clone, clientInfo.recipient);
        emit NewInstance(clone);
    }

    function claimFees(
        uint256 uid_,
        address[] calldata accounts_
    ) external override onlyRole(SERVER_ROLE) returns (uint256[] memory success) {
        Types.PaymentInfo memory paymentInfo_ = paymentInfo;
        return _claimFees(uid_, paymentInfo_, admin(), accounts_);
    }

    function distribute(ICryptoPaymentUpgradeable[] calldata instances_) external override onlyRole(OPERATOR_ROLE) {
        uint256 length = instances_.length;
        for (uint i = 0; i < length; ) {
            instances_[i].distribute();
            unchecked {
                ++i;
            }
        }
    }

    function admin() public view override returns (address) {
        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }

    function changeAdmin(address newAdmin_) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, newAdmin_);
    }

    function setPayment(Types.PaymentInfo calldata payment_) external override onlyRole(OPERATOR_ROLE) {
        _setPayment(payment_);
    }

    function setImplement(address implement_) external override onlyRole(UPGRADER_ROLE) {
        _setImplement(implement_);
    }

    /* solhint-disable no-empty-blocks */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}
}
