// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {AXXISSale} from "../src/Sale.sol";

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


contract EasyMintableMockERC20 is MockERC20 {
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract NewSaleImpl is UUPSUpgradeable {
    function allocations(address) public returns (uint256) {
        return 999;
    }

    function _authorizeUpgrade(address) internal override {}
}

contract AXXISSaleTest is Test {
    AXXISSale public sale;

    IERC20 public usdt;
    IERC20 public usdc;
    IERC20 public dai;

    address admin = address(0x123);

    function setUp() public {
        EasyMintableMockERC20 usdtMock = new EasyMintableMockERC20();
        usdtMock.initialize("USDT", "USDT", 6);
        usdtMock.mint(address(this), 10_000_000_000000);
        usdt = IERC20(address(usdtMock));

        EasyMintableMockERC20 usdcMock = new EasyMintableMockERC20();
        usdcMock.initialize("USDC", "USDC", 8);
        usdcMock.mint(address(this), 5_000_000_00000000);
        usdc = IERC20(address(usdcMock));

        EasyMintableMockERC20 daiMock = new EasyMintableMockERC20();
        daiMock.initialize("DAI", "DAI", 18);
        daiMock.mint(address(this), 10_000_000000000000000000);
        dai = IERC20(address(daiMock));

        sale = new AXXISSale();
        ERC1967Proxy proxy = new ERC1967Proxy(address(sale), bytes(""));
        sale = AXXISSale(address(proxy));
        IERC20[] memory supportedCurrencies = new IERC20[](2);
        supportedCurrencies[0] = usdt;
        supportedCurrencies[1] = usdc;
        sale.initialize(admin, supportedCurrencies);
    }

    function test_buyFromDifferentAccountsUsingDifferentCurrencies() public {
        address buyer1 = address(0x1);
        address buyer2 = address(0x2);

        vm.deal(buyer1, 10 ether);
        usdt.transfer(buyer1, 1_000_000_000000);
        usdc.transfer(buyer1, 1_000_000_00000000);
        vm.deal(buyer2, 10 ether);
        usdt.transfer(buyer2, 1_000_000_000000);
        usdc.transfer(buyer2, 1_000_000_00000000);

        uint256 usdtAdminBalanceBefore = usdt.balanceOf(admin);
        uint256 usdcAdminBalanceBefore = usdc.balanceOf(admin);

        // Buyer 1 buys 100 USDT worth of tokens.
        vm.startPrank(buyer1);
        usdt.approve(address(sale), 10_000_000000);
        sale.buy(usdt, 100_000000);
        assertEq(sale.allocations(buyer1), 10000);
        vm.stopPrank();

        // Buyer 2 buys 700 USDC worth of tokens.
        vm.startPrank(buyer2);
        usdc.approve(address(sale), 10_000_00000000);
        sale.buy(usdc, 700_00000000);
        assertEq(sale.allocations(buyer2), 70000);
        vm.stopPrank();

        // Buyer 1 buys 123 USDT worth of tokens and 76 USDC worth of tokens.
        vm.startPrank(buyer1);
        usdt.approve(address(sale), 10_000_000000);
        sale.buy(usdt, 123_009999);
        assertEq(sale.allocations(buyer1), 22300);

        usdc.approve(address(sale), 10_000_00000000);
        sale.buy(usdc, 76_00999999);
        assertEq(sale.allocations(buyer1), 29900);
        vm.stopPrank();

        assertEq(
            usdt.balanceOf(admin),
            usdtAdminBalanceBefore + 100_000000 + 123_000000
        );
        assertEq(
            usdc.balanceOf(admin),
            usdcAdminBalanceBefore + 76_00000000 + 700_00000000
        );
    }

    function testFail_buyWithUnsupportedCurrency() public {
        vm.startPrank(address(this));
        dai.approve(address(sale), 10_000_000000000000000000);
        sale.buy(dai, 100_000000000000000000000);
    }

    function testFail_buyAfterSaleEnd() public {
        vm.startPrank(admin);
        sale.setEndTimestamp(block.timestamp - 1);
        usdt.approve(address(sale), 10_000_000000);
        sale.buy(usdt, 100_000000);
        vm.stopPrank();
    }

    function testFail_endSaleAsNonOwner() public {
        sale.setEndTimestamp(block.timestamp + 1);
    }

    function test_adminCanChangeImplementation() public {
        NewSaleImpl newimpl = new NewSaleImpl();
        vm.startPrank(admin);
        sale.upgradeToAndCall(address(newimpl), bytes(""));
        vm.stopPrank();
        assertEq(sale.allocations(address(0x987)), 999);
    }

    function testFail_nonAdminProxyUpgrade() public {
        NewSaleImpl newimpl = new NewSaleImpl();
        sale.upgradeToAndCall(address(newimpl), bytes(""));
    }
}
