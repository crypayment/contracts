// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { Types } from "../libraries/Types.sol";

abstract contract PaymentUpgradeable is Initializable {
    Types.PaymentInfo public paymentInfo;

    function __Payment_init(Types.PaymentInfo calldata payment_) internal onlyInitializing {
        __Payment_init_unchained(payment_);
    }

    function __Payment_init_unchained(Types.PaymentInfo calldata payment_) internal onlyInitializing {
        _setPayment(payment_);
    }

    function _setPayment(Types.PaymentInfo calldata payment_) internal {
        paymentInfo = payment_;
    }

    uint256[19] private __gap;
}
