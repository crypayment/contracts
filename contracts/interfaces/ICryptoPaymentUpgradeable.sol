// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface ICryptoPaymentUpgradeable {
    error NotAuthorized();

    event Distribute();

    function distribute() external;

    function claimFees(uint256 uid_, address[] calldata accounts_) external returns (uint256[] memory success);
}
