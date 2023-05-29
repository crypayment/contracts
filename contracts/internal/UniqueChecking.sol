// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import { BitMaps } from "../libraries/BitMaps.sol";

error AlreadyUsed();

abstract contract UniqueChecking {
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private _isUsed;

    function _setUsed(uint256 uid_) internal {
        if (_isUsed.get(uid_)) revert AlreadyUsed();
        _isUsed.set(uid_);
    }

    function isUsed(uint256 uid_) external view returns (bool) {
        return _isUsed.get(uid_);
    }
}
