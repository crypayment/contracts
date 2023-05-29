// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface ICryptoPayment {
    error NotAuthorized();

    event Distribute();
    event Claimed(address indexed sender, uint256[] success);

    function distribute() external;
}
