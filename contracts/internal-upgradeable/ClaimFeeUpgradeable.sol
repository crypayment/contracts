// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { IERC20Upgradeable } from "../interfaces/IERC20Upgradeable.sol";
import { UniqueCheckingUpgradeable } from "./UniqueCheckingUpgradeable.sol";
import { Types } from "../libraries/Types.sol";

abstract contract ClaimFeeUpgradeable is UniqueCheckingUpgradeable {
    event Claimed(address indexed sender, uint256[] success);

    function _claimFees(
        uint256 uid_,
        Types.PaymentInfo memory paymentInfo_,
        address recipient_,
        address[] calldata accounts_
    ) internal returns (uint256[] memory success) {
        _setUsed(uid_);

        uint256 length = accounts_.length;
        success = new uint256[](length);

        bytes memory callData = abi.encodeCall(
            IERC20Upgradeable.transferFrom,
            (address(0), recipient_, paymentInfo_.amount)
        );

        address payment = paymentInfo_.token;
        bool ok;
        address account;
        for (uint256 i; i < length; ) {
            account = accounts_[i];

            assembly {
                mstore(add(callData, 0x24), account)
            }

            (ok, ) = payment.call(callData);

            success[i] = ok ? 2 : 1;

            unchecked {
                ++i;
            }
        }

        emit Claimed(msg.sender, success);
    }
}
