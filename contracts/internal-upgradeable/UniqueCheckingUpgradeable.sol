// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { BitMapsUpgradeable } from "../libraries/BitMapsUpgradeable.sol";

error AlreadyUsed();

abstract contract UniqueCheckingUpgradeable is Initializable {
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;

    BitMapsUpgradeable.BitMap private _isUsed;

    // function __UniqueChecking_init() internal onlyInitializing {}

    // function __UniqueChecking_init_unchained() internal onlyInitializing {}

    function _setUsed(uint256 uid_) internal {
        if (_isUsed.get(uid_)) revert AlreadyUsed();
        _isUsed.set(uid_);
    }

    function isUsed(uint256 uid_) external view returns (bool) {
        return _isUsed.get(uid_);
    }

    uint256[9] private __gap;
}
