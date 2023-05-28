// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import { Types } from "../libraries/Types.sol";
import { IFeeCollector } from "../interfaces/IFeeCollector.sol";

contract FeeCollector is IFeeCollector {
    uint256 public constant HUNDER_PERCENT = 10_000; // 100%
    Types.FeeInfo[] public feeInfos;

    function _configFees(uint256[] calldata indexes_, Types.FeeInfo[] calldata feeInfos_) internal {
        uint256 length = indexes_.length;
        if (feeInfos_.length != length) revert LengthMisMatch();

        uint256 index;
        Types.FeeInfo memory feeInfo;

        for (uint256 i = 0; i < length; ) {
            index = indexes_[i];
            feeInfo = feeInfos_[i];

            if (feeInfo.recipient == address(0)) revert InvalidRecipient();
            feeInfos[index] = feeInfo;
            unchecked {
                ++i;
            }
        }

        emit FeeUpdated();
    }

    function viewFees() external view returns (Types.FeeInfo[] memory feeInfoDetails) {
        uint256 length = feeInfos.length;

        feeInfoDetails = new Types.FeeInfo[](length);

        for (uint256 i = 0; i < length; ) {
            feeInfoDetails[i] = feeInfos[i];
            unchecked {
                ++i;
            }
        }
        return (feeInfoDetails);
    }

    uint256[45] private __gap;
}
