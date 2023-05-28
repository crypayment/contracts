// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library Types {
    struct CloneInfo {
        address instance;
        address creator;
    }

    struct FeeInfo {
        address recipient;
        uint96 percentage;
    }

    struct PaymentInfo {
        address token;
        uint96 amount;
    }
}
