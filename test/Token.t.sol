// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {AXXISToken} from "../src/Token.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract NewTokenImpl is UUPSUpgradeable {
    function balanceOf(address owner) public returns (uint256) {
        return 999;
    }

    function _authorizeUpgrade(address) internal override {}
}

contract AXXISTokenTest is Test {
    AXXISToken public token;
    address public admin;

    function setUp() public {
        AXXISToken impl = new AXXISToken();
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), bytes(""));
        token = AXXISToken(address(proxy));

        admin = address(0x1);
        vm.deal(admin, 1_000_000_000_000_000_000);

        token.initialize(admin);
    }

    function test_initial_balance() public {
        assertEq(token.balanceOf(admin), 800_000_000_000_000_000_000_000_000);
    }

    function test_extra_mint_is_impossible() public {
        vm.prank(admin);
        (bool success, ) = address(token).call(
            abi.encodeWithSignature("mint(address,uint256)", admin, 1)
        );
        assertEq(success, false);
    }

    function test_transferByOwner() public {
        address to = address(0x2);

        vm.prank(admin);
        token.transfer(to, 1);
    }

    function test_transferByOwnerByApproval() public {
        address to = address(0x2);

        vm.prank(admin);
        token.approve(to, 1);

        vm.prank(to);
        token.transferFrom(admin, to, 1);
    }

    function testFail_transferNotByOwner() public {
        address to = address(0x2);
        token.transferFrom(admin, to, 1);
    }

    function test_upgradeProxy() public {
        NewTokenImpl newimpl = new NewTokenImpl();

        vm.prank(admin);
        token.upgradeToAndCall(address(newimpl), bytes(""));

        assertEq(token.balanceOf(address(0)), 999);
    }

    function testFail_nonAdminProxyUpgrade() public {
        NewTokenImpl newimpl = new NewTokenImpl();
        token.upgradeToAndCall(address(newimpl), bytes(""));
    }
}