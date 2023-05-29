// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { EnumerableSet } from "../libraries/EnumerableSet.sol";
import { IBusinessAddressesUpgradeable } from "../interfaces/IBusinessAddressesUpgradeable.sol";

contract BusinessAddressesUpgradeable is Initializable, OwnableUpgradeable, IBusinessAddressesUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet internal _businessAddressSet;

    modifier onlyBusiness() {
        if (!_isBusinessAddress(_msgSender())) revert Account__NotAuthorize();
        _;
    }

    function __BusinessAddresses_init(address[] calldata address_) internal onlyInitializing {
        __BusinessAddresses_init_unchained(address_);
    }

    function __BusinessAddresses_init_unchained(address[] calldata address_) internal onlyInitializing {
        _acceptBusiness(address_);
    }

    function _isBusinessAddress(address account) internal view returns (bool) {
        return _businessAddressSet.contains(account);
    }

    function _acceptBusiness(address[] calldata addresses_) internal {
        uint256 length = addresses_.length;
        for (uint256 i = 0; i < length; ) {
            address tokenAddress = addresses_[i];
            if (!_businessAddressSet.add(tokenAddress)) revert Account__Existed();
            unchecked {
                ++i;
            }
        }
        emit BusinessAdded(addresses_);
    }

    function _cancelBusiness(address[] calldata addresses_) internal {
        uint256 length = addresses_.length;
        for (uint256 i = 0; i < length; ) {
            address tokenAddress = addresses_[i];
            if (!_businessAddressSet.remove(tokenAddress)) revert Account__NotExist();
            unchecked {
                ++i;
            }
        }
        emit BusinessCancelled(addresses_);
    }

    function acceptBusiness(address[] calldata addresses_) external onlyOwner {
        _acceptBusiness(addresses_);
    }

    function cancelBusiness(address[] calldata addresses_) external onlyOwner {
        _cancelBusiness(addresses_);
    }

    function isBusinessAddress(address account) external view returns (bool) {
        return _isBusinessAddress(account);
    }

    function viewBusinessAddresses() external view returns (address[] memory) {
        return (_businessAddressSet.values());
    }

    uint256[19] private __gap;
}
