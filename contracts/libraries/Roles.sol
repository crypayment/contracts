// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library Roles {
    bytes32 public constant SERVER_ROLE = 0xa8a7bc421f721cb936ea99efdad79237e6ee0b871a2a08cf648691f9584cdc77;
    bytes32 public constant OPERATOR_ROLE = 0x97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b929;
    bytes32 public constant UPGRADER_ROLE = 0x189ab7a9244df0848122154315af71fe140f3db0fe014031783b0946b8c9d2e3;
    bytes32 public constant TREASURER_ROLE = 0x3496e2e73c4d42b75d702e60d9e48102720b8691234415963a5a857b86425d07;
}
