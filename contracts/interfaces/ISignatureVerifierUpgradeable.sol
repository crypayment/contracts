// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import { Types } from "../libraries/Types.sol";

interface ISignatureVerifierUpgradeable {
    /* ========== ERRORS ========== */

    error ExpiredSignature();
    error InvalidOracle();
    error DuplicateSignatures();
    error NotEnoughOracles();

    function threshHold() external view returns (uint8);

    function verify(bytes32 hash_, uint256 deadline_, Types.Signature[] calldata signs_) external view returns (bool);
}
