// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { AccessControlEnumerableUpgradeable } from "./internal-upgradeable/AccessControlEnumerableUpgradeable.sol";
import { FactoryUpgradeable } from "./internal-upgradeable/FactoryUpgradeable.sol";
import { PaymentUpgradeable } from "./internal-upgradeable/PaymentUpgradeable.sol";

import { UniqueChecking } from "./internal/UniqueChecking.sol";

import { ICryptoPayment } from "./interfaces/ICryptoPayment.sol";
import { ICryptoPaymentFactoryUpgradeable } from "./interfaces/ICryptoPaymentFactoryUpgradeable.sol";
import { IERC20Upgradeable } from "./interfaces/IERC20Upgradeable.sol";

import { ErrorHandler } from "./libraries/ErrorHandler.sol";
import { Types } from "./libraries/Types.sol";
import { HUNDER_PERCENT, OPERATOR_ROLE, SERVER_ROLE, UPGRADER_ROLE } from "./libraries/Constants.sol";

contract CryptoPaymentFactoryUpgradeable is
    ICryptoPaymentFactoryUpgradeable,
    Initializable,
    UUPSUpgradeable,
    AccessControlEnumerableUpgradeable,
    FactoryUpgradeable,
    PaymentUpgradeable,
    UniqueChecking
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
        __AccessControl_init();
        __UUPSUpgradeable_init();
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
    ) external onlyRole(OPERATOR_ROLE) {
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
    ) external onlyRole(SERVER_ROLE) returns (uint256[] memory success) {
        _setUsed(uid_);

        uint256 length = accounts_.length;
        success = new uint256[](length);

        bytes memory callData = abi.encodeCall(
            IERC20Upgradeable.transferFrom,
            (address(0), admin(), paymentInfo.amount)
        );

        address payment = paymentInfo.token;
        bool ok;
        address account;

        for (uint256 i; i < length; ) {
            account = accounts_[i];

            assembly {
                mstore(add(callData, 0x24), account)
            }

            (ok, ) = payment.call(callData);

            success[i] = ok ? 2 : 1;

            unchecked {
                ++i;
            }
        }

        emit Claimed(_msgSender(), success);
    }

    function distribute(ICryptoPayment[] calldata instances_) external onlyRole(OPERATOR_ROLE) {
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

    function setPayment(Types.PaymentInfo calldata payment_) external onlyRole(OPERATOR_ROLE) {
        _setPayment(payment_);
    }

    function setImplement(address implement_) external onlyRole(UPGRADER_ROLE) {
        _setImplement(implement_);
    }

    /* solhint-disable no-empty-blocks */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}
}
