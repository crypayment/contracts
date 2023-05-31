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

    bytes32 private constant TRANSFER_SELECTOR = 0xa9059cbb00000000000000000000000000000000000000000000000000000000;
    bytes32 private constant BALANCEOF_SELECTOR = 0x70a0823100000000000000000000000000000000000000000000000000000000;

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
        address payment = paymentInfo.token;

        assembly {
            let contractAddress := address()
            let callResult
            let mptr := mload(0x40)
            mstore(mptr, BALANCEOF_SELECTOR)
            mstore(add(mptr, 0x04), contractAddress)

            callResult := staticcall(gas(), calldataload(payment), mptr, 0x24, 0x00, 0x20)

            if iszero(callResult) {
                revert(0, 0)
            }

            let total := mload(0x00)

            for {
                let recipientSlot := add(recipients, 0x20)
                let feeSlot := add(fees, 0x20)
                let end := add(recipientSlot, shl(5, length))
            } lt(recipientSlot, end) {
                recipientSlot := add(recipientSlot, 0x20)
                feeSlot := add(feeSlot, 0x20)
            } {
                if gt(total, 0) {
                    mptr := mload(0x40)
                    mstore(mptr, TRANSFER_SELECTOR)
                    mstore(add(mptr, 0x04), mload(recipientSlot))
                    mstore(add(mptr, 0x24), div(mul(total, mload(feeSlot)), HUNDER_PERCENT))

                    callResult := and(
                        or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                        call(gas(), calldataload(payment), 0, mptr, 0x44, 0, 0x20)
                    )

                    if iszero(callResult) {
                        revert(0, 0)
                    }
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
