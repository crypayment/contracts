// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IERC20Upgradeable {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
