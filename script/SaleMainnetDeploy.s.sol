// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {AXXISToken} from "../src/Token.sol";
import {AXXISSale} from "../src/Sale.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";


contract SaleMainnetDeploy is Script {
    function setUp() public {}

    function run() public {
        IERC20[] memory supportedCurrencies = new IERC20[](2);
        supportedCurrencies[0] = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        supportedCurrencies[1] = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

        vm.startBroadcast();
        AXXISSale sale = new AXXISSale();
        ERC1967Proxy proxy = new ERC1967Proxy(address(sale), bytes(""));
        sale = AXXISSale(address(proxy));
        sale.initialize(vm.envAddress("OWNER_ADDRESS"), supportedCurrencies);
        vm.stopBroadcast();
        console2.log("AXXIS Sale address: ", address(sale));
    }
}
