// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Types } from "../libraries/Types.sol";

interface ICryptoPaymentUpgradeable {
    error NotAuthorized();
    error InvalidSignatures();

    event Distribute();

    function distribute() external;

    function claimFees(
        Types.Claim calldata claim_,
        Types.Signature[] calldata signatures_
    ) external returns (uint256[] memory success);
}
