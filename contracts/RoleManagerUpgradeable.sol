// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { AccessControlEnumerableUpgradeable } from "./internal-upgradeable/AccessControlEnumerableUpgradeable.sol";
import { SignatureVerifierUpgradeable } from "./internal-upgradeable/SignatureVerifierUpgradeable.sol";

import { IRoleManagerUpgradeable } from "./interfaces/IRoleManagerUpgradeable.sol";

import { OPERATOR_ROLE, UPGRADER_ROLE } from "./libraries/Constants.sol";

contract RoleManagerUpgradeable is
    Initializable,
    UUPSUpgradeable,
    IRoleManagerUpgradeable,
    AccessControlEnumerableUpgradeable,
    SignatureVerifierUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address admin_,
        address[] calldata operators_,
        address[] calldata servers_,
        string calldata name_,
        string calldata version_,
        uint8 threshold_
    ) external initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __SignatureVerifier_init(name_, version_, threshold_, servers_);

        bytes32 operatorRole = OPERATOR_ROLE;
        _grantRoles(operatorRole, operators_);
        _grantRole(operatorRole, admin_);
        _grantRole(UPGRADER_ROLE, admin_);
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
    }

    function admin() public view override returns (address) {
        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }

    function changeAdmin(address newAdmin_) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, newAdmin_);
    }

    /* solhint-disable no-empty-blocks */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}
}
