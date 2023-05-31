// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import { ClaimFeeUpgradeable } from "./internal-upgradeable/ClaimFeeUpgradeable.sol";
import { FactoryUpgradeable } from "./internal-upgradeable/FactoryUpgradeable.sol";
import { PaymentUpgradeable } from "./internal-upgradeable/PaymentUpgradeable.sol";

import { IAccessControlUpgradeable } from "./interfaces/IAccessControlUpgradeable.sol";
import { ICryptoPaymentUpgradeable } from "./interfaces/ICryptoPaymentUpgradeable.sol";
import { ICryptoPaymentFactoryUpgradeable } from "./interfaces/ICryptoPaymentFactoryUpgradeable.sol";
import { IRoleManagerUpgradeable } from "./interfaces/IRoleManagerUpgradeable.sol";
import { ISignatureVerifierUpgradeable } from "./interfaces/ISignatureVerifierUpgradeable.sol";

import { ErrorHandler } from "./libraries/ErrorHandler.sol";
import { Types } from "./libraries/Types.sol";
import { HUNDER_PERCENT, OPERATOR_ROLE, SERVER_ROLE, UPGRADER_ROLE } from "./libraries/Constants.sol";

contract CryptoPaymentFactoryUpgradeable is
    ICryptoPaymentFactoryUpgradeable,
    Initializable,
    UUPSUpgradeable,
    ContextUpgradeable,
    ClaimFeeUpgradeable,
    FactoryUpgradeable,
    PaymentUpgradeable
{
    using ErrorHandler for bool;
    using Types for Types.Claim;

    bytes4 private constant INITIALIZE_SELECTOR = 0x1cd8a2e0;

    address public override roleManager;

    mapping(bytes32 => Types.CloneInfo) public instance;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    modifier onlyRole(bytes32 role) {
        if (!_checkRole(role)) revert Factory__NotAuthorized();
        _;
    }

    function initialize(
        address implement_,
        address roleManager_,
        Types.PaymentInfo calldata payment_
    ) external initializer {
        roleManager = roleManager_;
        __Factory_init_unchained(implement_);
        __Payment_init_unchained(payment_);
    }

    function createContract(
        bytes32 salt_,
        Types.PaymentInfo calldata paymentInfo_,
        Types.FeeInfo calldata clientInfo,
        Types.FeeInfo calldata agentInfo
    ) external override onlyRole(OPERATOR_ROLE) {
        Types.FeeInfo memory adminInfo = Types.FeeInfo(
            IRoleManagerUpgradeable(roleManager).admin(),
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
        Types.Claim calldata claim_,
        Types.Signature[] calldata signatures_
    ) external override onlyRole(SERVER_ROLE) returns (uint256[] memory success) {
        Types.PaymentInfo memory paymentInfo_ = paymentInfo;

        bytes32 claimHash = claim_.hash();
        if (!ISignatureVerifierUpgradeable(roleManager).verify(claimHash, claim_.deadline, signatures_)) {
            revert Factory__InvalidSignatures();
        }

        return _claimFees(claim_.nonce, paymentInfo_, IRoleManagerUpgradeable(roleManager).admin(), claim_.accounts);
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

    function setPayment(Types.PaymentInfo calldata payment_) external override onlyRole(OPERATOR_ROLE) {
        _setPayment(payment_);
    }

    function setImplement(address implement_) external override onlyRole(UPGRADER_ROLE) {
        _setImplement(implement_);
    }

    /* solhint-disable no-empty-blocks */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    function _checkRole(bytes32 role) internal view returns (bool) {
        if (IAccessControlUpgradeable(roleManager).hasRole(role, _msgSender())) return true;

        return false;
    }
}
