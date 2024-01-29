// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


contract AXXISToken is ERC20Upgradeable, UUPSUpgradeable, OwnableUpgradeable {
    constructor() {
        _disableInitializers();
    }

    function initialize(address supply_receiver) public initializer {
        __ERC20_init("AXXIS", "XXS");
        __UUPSUpgradeable_init();
        __Ownable_init(supply_receiver);
        
        uint256 supply = 800_000_000_000 * 10**decimals();
        _mint(supply_receiver, supply);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}