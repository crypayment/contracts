// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { AccessControlEnumerableUpgradeable } from "./AccessControlEnumerableUpgradeable.sol";
import { EIP712Upgradeable, ECDSAUpgradeable } from "./EIP712Upgradeable.sol";
import { ISignatureVerifierUpgradeable } from "../interfaces/ISignatureVerifierUpgradeable.sol";
import { Types } from "../libraries/Types.sol";
import { SIGNER_ROLE } from "../libraries/Constants.sol";

error LowThreshold();

contract SignatureVerifierUpgradeable is
    ISignatureVerifierUpgradeable,
    Initializable,
    AccessControlEnumerableUpgradeable,
    EIP712Upgradeable
{
    uint8 internal _threshHold;

    function __SignatureVerifier_init(
        string calldata name_,
        string calldata version_,
        uint8 threshold_,
        address[] calldata oracles_
    ) internal onlyInitializing {
        __SignatureVerifier_init_unchained(name_, version_, threshold_, oracles_);
    }

    function __SignatureVerifier_init_unchained(
        string calldata name_,
        string calldata version_,
        uint8 threshold_,
        address[] calldata oracles_
    ) internal onlyInitializing {
        __AccessControlEnumerable_init_unchained();
        __EIP712_init_unchained(name_, version_);
        _setThreshhold(threshold_);
        _grantRoles(SIGNER_ROLE, oracles_);
    }

    function _setThreshhold(uint8 threshold_) internal {
        if (threshold_ == 0) revert LowThreshold();
        _threshHold = threshold_;
    }

    /* ========== VIEW ========== */

    function threshHold() external view override returns (uint8) {
        return _threshHold;
    }

    function verify(
        bytes32 hash_,
        uint256 deadline_,
        Types.Signature[] calldata signs_
    ) external view override returns (bool) {
        // ExpiredSignature
        if (deadline_ < block.timestamp) return false;

        // NotEnoughOracles
        uint256 length = signs_.length;
        if (length < _threshHold) return false;

        address recoveredAddress;
        address lastAddress;
        bytes32 digest = _hashTypedDataV4(hash_);

        for (uint256 i; i < length; ) {
            (recoveredAddress, ) = ECDSAUpgradeable.tryRecover(digest, signs_[i].v, signs_[i].r, signs_[i].s);

            // DuplicateSignatures
            if (recoveredAddress != address(0) && recoveredAddress < lastAddress) return false;

            // InvalidOracle
            if (!hasRole(SIGNER_ROLE, recoveredAddress)) return false;

            lastAddress = recoveredAddress;

            unchecked {
                ++i;
            }
        }

        return true;
    }
}
