// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { ClonesUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { ErrorHandler } from "../libraries/ErrorHandler.sol";
import { EnumerableSet } from "../libraries/EnumerableSet.sol";

abstract contract FactoryUpgradeable is Initializable {
    using ErrorHandler for bool;
    using ClonesUpgradeable for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public implementation;

    EnumerableSet.AddressSet internal _instances;

    function __Factory_init(address implement_) internal onlyInitializing {
        __Factory_init_unchained(implement_);
    }

    function __Factory_init_unchained(address implement_) internal onlyInitializing {
        _setImplement(implement_);
    }

    function _setImplement(address implement_) internal {
        implementation = implement_;
    }

    function _cheapClone(bytes32 salt_, bytes4 selector_, bytes memory args_) internal returns (address clone) {
        clone = implementation.cloneDeterministic(salt_);
        (bool success, bytes memory revertData) = clone.call(abi.encodePacked(selector_, args_));

        if (!success) success.handleRevertIfNotSuccess(revertData);

        _instances.add(clone);
    }

    function viewInstanceAddresses(uint256 cursor, uint256 size) external view returns (address[] memory instances) {
        // skip the overflow check
        instances = new address[](size);
        for (uint i = 0; i < size; ) {
            instances[i] = _instances.at(cursor + i);
            unchecked {
                ++i;
            }
        }
    }

    uint256[47] private __gap;
}
