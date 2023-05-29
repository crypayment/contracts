// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import { Types } from "../libraries/Types.sol";

abstract contract Payment {
    Types.PaymentInfo public paymentInfo;

    function _setPayment(Types.PaymentInfo calldata payment_) internal {
        paymentInfo = payment_;
    }
}
