// SPDX-License-Identifier: MIT
import { Types } from "../libraries/Types.sol";

pragma solidity 0.8.19;

interface IFeeCollector {
    error LengthMisMatch();
    error InvalidRecipient();

    event FeeUpdated();

    function viewFees() external view returns (address[] memory recipients, uint256[] memory percentages);
}
