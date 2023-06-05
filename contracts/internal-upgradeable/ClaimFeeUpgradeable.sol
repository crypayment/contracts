// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { IERC20Upgradeable } from "../interfaces/IERC20Upgradeable.sol";
import { UniqueCheckingUpgradeable } from "./UniqueCheckingUpgradeable.sol";
import { Types } from "../libraries/Types.sol";
import { Bytes32Address } from "../libraries/Bytes32Address.sol";

//         = 96        + 160
// CLAIMID = PAYMENTID + ADDRESS
abstract contract ClaimFeeUpgradeable is UniqueCheckingUpgradeable {
    event Claimed(address indexed sender, uint256[] success);

    function isClaimed(address account, uint256 payId) external view returns (bool) {
        return _used(_getClaimId(account, payId));
    }

    function _getClaimId(address account, uint256 payId) internal pure returns (uint256 paymentId) {
        paymentId = (payId << 160) | Bytes32Address.fillLast96Bits(account);
    }

    function _claimFees(
        uint256 uid_,
        Types.PaymentInfo memory paymentInfo_,
        address recipient_,
        address[] calldata accounts_
    ) internal returns (uint256[] memory success) {
        uint256 length = accounts_.length;
        success = new uint256[](length);

        bytes memory callData = abi.encodeCall(
            IERC20Upgradeable.transferFrom,
            (address(0), recipient_, paymentInfo_.amount)
        );

        uint256 paymentId;
        address paymentToken = paymentInfo_.token;
        address account;
        bool ok;

        for (uint256 i; i < length; ) {
            account = accounts_[i];
            paymentId = _getClaimId(account, uid_);

            if (_used(paymentId)) {
                success[i] = 2;
            } else {
                assembly {
                    mstore(add(callData, 0x24), account)
                }

                (ok, ) = paymentToken.call(callData);
                if (ok) {
                    success[i] = 2;
                    _setUsed(paymentId);
                } else {
                    success[i] = 1;
                }
            }

            unchecked {
                ++i;
            }
        }

        emit Claimed(msg.sender, success);
    }
}
