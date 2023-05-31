// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import { ClaimFeeUpgradeable } from "./internal-upgradeable/ClaimFeeUpgradeable.sol";
import { FeeCollectorUpgradeable } from "./internal-upgradeable/FeeCollectorUpgradeable.sol";
import { PaymentUpgradeable } from "./internal-upgradeable/PaymentUpgradeable.sol";
import { SignatureVerifierUpgradeable } from "./internal-upgradeable/SignatureVerifierUpgradeable.sol";

import { IAccessControlUpgradeable } from "./interfaces/IAccessControlUpgradeable.sol";
import { IERC20Upgradeable } from "./interfaces/IERC20Upgradeable.sol";
import { ICryptoPaymentUpgradeable } from "./interfaces/ICryptoPaymentUpgradeable.sol";
import { ICryptoPaymentFactoryUpgradeable } from "./interfaces/ICryptoPaymentFactoryUpgradeable.sol";
import { IRoleManagerUpgradeable } from "./interfaces/IRoleManagerUpgradeable.sol";
import { ISignatureVerifierUpgradeable } from "./interfaces/ISignatureVerifierUpgradeable.sol";

import { Types } from "./libraries/Types.sol";
import { HUNDER_PERCENT, OPERATOR_ROLE, SERVER_ROLE } from "./libraries/Constants.sol";

contract CryptoPayment is
    ICryptoPaymentUpgradeable,
    Initializable,
    ContextUpgradeable,
    ClaimFeeUpgradeable,
    FeeCollectorUpgradeable,
    PaymentUpgradeable,
    SignatureVerifierUpgradeable
{
    using Types for Types.Claim;

    address public factory;
    address public roleManager;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    modifier onlyFactoryRole(bytes32 role) {
        if (!_checkFactoryRole(role)) revert NotAuthorized();
        _;
    }

    function initialize(
        Types.PaymentInfo calldata paymentInfo_,
        Types.FeeInfo calldata adminInfo_,
        Types.FeeInfo calldata clientInfo_,
        Types.FeeInfo calldata agentInfo_,
        address roleManager_
    ) external initializer {
        factory = _msgSender();
        roleManager = roleManager_;
        __Payment_init(paymentInfo_);
        __FeeCollector_init(adminInfo_, clientInfo_, agentInfo_);
    }

    function distribute() external override onlyFactoryRole(OPERATOR_ROLE) {
        (address[] memory recipients, uint256[] memory fees) = viewFees();
        uint256 length = recipients.length;

        IERC20Upgradeable token = IERC20Upgradeable(paymentInfo.token);
        uint256 balance = token.balanceOf(address(this));

        if (balance > 0) {
            for (uint i = 0; i < length; ) {
                unchecked {
                    token.transfer(recipients[i], (balance * HUNDER_PERCENT) / fees[i]);
                    ++i;
                }
            }
        }

        emit Distribute();
    }

    function claimFees(
        Types.Claim calldata claim_,
        Types.Signature[] calldata signatures_
    ) external override onlyFactoryRole(SERVER_ROLE) returns (uint256[] memory success) {
        Types.PaymentInfo memory paymentInfo_ = paymentInfo;

        bytes32 claimHash = claim_.hash();
        if (!ISignatureVerifierUpgradeable(roleManager).verify(claimHash, claim_.deadline, signatures_)) {
            revert InvalidSignatures();
        }

        return _claimFees(claim_.nonce, paymentInfo_, address(this), claim_.accounts);
    }

    function config(
        Types.PaymentInfo calldata paymentInfo_,
        Types.FeeInfo calldata clientInfo_,
        Types.FeeInfo calldata agentInfo_
    ) external onlyFactoryRole(OPERATOR_ROLE) {
        Types.FeeInfo memory adminInfo = Types.FeeInfo(
            IRoleManagerUpgradeable(factory).admin(),
            HUNDER_PERCENT - clientInfo_.percentage - agentInfo_.percentage
        );

        _setPayment(paymentInfo_);
        _configFees(adminInfo, clientInfo_, agentInfo_);
    }

    function _checkFactoryRole(bytes32 role) internal view returns (bool) {
        address sender = _msgSender();
        // direct call
        if (IAccessControlUpgradeable(roleManager).hasRole(role, sender)) return true;

        // forward call
        if (sender == factory && IAccessControlUpgradeable(roleManager).hasRole(role, tx.origin)) return true;
        return false;
    }
}
