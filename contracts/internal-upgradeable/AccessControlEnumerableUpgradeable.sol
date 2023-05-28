// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { BitMapsUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import { IAccessControlEnumerableUpgradeable } from "../interfaces/IAccessControlEnumerableUpgradeable.sol";
import { EnumerableSet } from "../libraries/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is
    Initializable,
    IAccessControlEnumerableUpgradeable,
    AccessControlUpgradeable
{
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    // function __AccessControlEnumerable_init() internal onlyInitializing {}

    // function __AccessControlEnumerable_init_unchained() internal onlyInitializing {}

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function getRoleMembers(bytes32 role) external view virtual returns (address[] memory) {
        return _roleMembers[role].values();
    }

    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _getRoleMemberCount(role);
    }

    function _getRoleMemberCount(bytes32 role) internal view returns (uint256) {
        return _roleMembers[role].length();
    }

    function _grantRole(bytes32 role, address account) internal virtual override {
        if (role == DEFAULT_ADMIN_ROLE && _getRoleMemberCount(role) == 1)
            revert AccessControlEnumerableUpgradeable__ExceedLimit();
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    uint256[49] private __gap;
}
