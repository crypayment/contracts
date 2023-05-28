// SPDX-License-Identifier: MIT
import { Types } from "../libraries/Types.sol";

pragma solidity 0.8.20;

interface IFeeCollector {
    error LengthMisMatch();
    error InvalidRecipient();

    event FeeUpdated();

    function viewFees() external view returns (Types.FeeInfo[] memory feeInfoDetails);
}
