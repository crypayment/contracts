// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import { Types } from "../libraries/Types.sol";
import { IFeeCollector } from "../interfaces/IFeeCollector.sol";

// Fixed position => do not use Enumrable
contract FeeCollector is IFeeCollector {
    uint256 public constant HUNDER_PERCENT = 10_000;
    Types.FeeInfo[] private _feeInfos;

    function _addFee(Types.FeeInfo calldata feeInfo_) internal {
        if (feeInfo_.recipient != address(0)) _feeInfos.push(feeInfo_);
    }

    function _updateFee(uint256 index_, Types.FeeInfo memory feeInfo_) internal {
        if (feeInfo_.recipient == address(0)) revert InvalidRecipient();
        _feeInfos[index_] = feeInfo_;
    }

    function _configFees(
        Types.FeeInfo memory adminInfo_,
        Types.FeeInfo memory clientInfo_,
        Types.FeeInfo memory agentInfo_
    ) internal {
        _updateFee(0, adminInfo_);
        _updateFee(1, clientInfo_);
        _updateFee(2, agentInfo_);
        emit FeeUpdated();
    }

    function viewFees() public view returns (address[] memory recipients, uint256[] memory percentages) {
        uint256 length = _feeInfos.length;

        recipients = new address[](length);
        percentages = new uint256[](length);

        for (uint256 i = 0; i < length; ) {
            recipients[i] = _feeInfos[i].recipient;
            percentages[i] = (_feeInfos[i].percentage);
            unchecked {
                ++i;
            }
        }
        return (recipients, percentages);
    }

    uint256[45] private __gap;
}
