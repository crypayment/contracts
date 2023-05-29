// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";

import { FeeCollector } from "./internal/FeeCollector.sol";
import { UniqueChecking } from "./internal/UniqueChecking.sol";

import { ICryptoPaymentFactoryUpgradeable } from "./interfaces/ICryptoPaymentFactoryUpgradeable.sol";
import { ICryptoPayment } from "./interfaces/ICryptoPayment.sol";
import { IERC20Upgradeable } from "./interfaces/IERC20Upgradeable.sol";
import { IAccessControlUpgradeable } from "./interfaces/IAccessControlUpgradeable.sol";

import { Types } from "./libraries/Types.sol";
import { Roles } from "./libraries/Roles.sol";

contract CryptoPayment is ICryptoPayment, Initializable, Context, FeeCollector, UniqueChecking {
    bytes32 private constant TRANSFER_SELECTOR = 0xa9059cbb00000000000000000000000000000000000000000000000000000000;
    bytes32 private constant BALANCEOF_SELECTOR = 0x70a0823100000000000000000000000000000000000000000000000000000000;

    receive() external payable {}

    IAccessControlUpgradeable public factory;
    Types.PaymentInfo public paymentInfo;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    modifier onlyFactoryRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    function initialize(
        // Types.PaymentInfo calldata paymentInfo_,
        Types.FeeInfo calldata adminInfo_,
        Types.FeeInfo calldata clientInfo_,
        Types.FeeInfo calldata agentInfo_
    ) external initializer {
        factory = IAccessControlUpgradeable(_msgSender());
        _addFee(adminInfo_);
        _addFee(clientInfo_);
        _addFee(agentInfo_);
    }

    function distribute() external onlyFactoryRole(Roles.OPERATOR_ROLE) {
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

        emit RewardsSplitted();
    }

    function claimFees(
        uint256 uid_,
        address[] calldata accounts_
    ) external onlyFactoryRole(Roles.SERVER_ROLE) returns (uint256[] memory success) {
        _setUsed(uid_);

        uint256 length = accounts_.length;
        success = new uint256[](length);

        bytes memory callData = abi.encodeCall(
            IERC20Upgradeable.transferFrom,
            (address(0), address(this), paymentInfo.amount)
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

    function _checkRole(bytes32 role) internal view {
        if (!factory.hasRole(role, _msgSender())) revert NotAuthorized();
    }
}