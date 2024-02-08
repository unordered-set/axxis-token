// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {AXXISSale} from "../src/Sale.sol";

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract EasyMintableMockERC20 is MockERC20 {
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract AXXISSaleTest is Test {
    AXXISSale public sale;

    IERC20 public usdt;
    IERC20 public usdc;
    IERC20 public dai;

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
        sale.initialize(address(this), supportedCurrencies);
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

        uint256 usdtAdminBalanceBefore = usdt.balanceOf(address(this));
        uint256 usdcAdminBalanceBefore = usdc.balanceOf(address(this));

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
            usdt.balanceOf(address(this)),
            usdtAdminBalanceBefore + 100_000000 + 123_000000
        );
        assertEq(
            usdc.balanceOf(address(this)),
            usdcAdminBalanceBefore + 76_00000000 + 700_00000000
        );
    }

    function testFail_buyWithUnsupportedCurrency() public {
        vm.startPrank(address(this));
        dai.approve(address(sale), 10_000_000000000000000000);
        sale.buy(dai, 100_000000000000000000000);
    }

    function testFail_buyAfterSaleEnd() public {
        sale.setEndTimestamp(block.timestamp - 1);
        usdt.approve(address(sale), 10_000_000000);
        sale.buy(usdt, 100_000000);
    }

    function testFail_endSaleAsNonOwner() public {
        vm.deal(address(0x1), 10 ether);
        vm.startPrank(address(0x1));
        sale.setEndTimestamp(block.timestamp + 1);
    }
}
