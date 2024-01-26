// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {AXXISToken} from "../src/Token.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract FullNewDeployScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        AXXISToken token = new AXXISToken();
        ERC1967Proxy proxy = new ERC1967Proxy(address(token), "");
        token = AXXISToken(address(proxy));
        token.initialize(vm.envAddress("OWNER_ADDRESS"));
        vm.stopBroadcast();
        console2.log("AXXIS proxy address: ", address(token));
    }
}
