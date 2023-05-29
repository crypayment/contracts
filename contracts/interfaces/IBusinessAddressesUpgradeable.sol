// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IBusinessAddressesUpgradeable {
    event BusinessAdded(address[] addresses);
    event BusinessCancelled(address[] addresses);

    error Account__Existed();
    error Account__NotExist();
    error Account__NotAuthorize();
}
