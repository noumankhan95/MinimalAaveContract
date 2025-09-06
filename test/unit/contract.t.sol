//SPDX-License-Identifier:MIT

pragma solidity ^0.8.20;
import {Test} from "forge-std/Test.sol";
import {Deploy} from "../../script/Deploy.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DefiCoin} from "../../src/DefiCoin.sol";
import {Market} from "../../src/Market.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {WethMock} from "test/mocks/WethMock.sol";
import {WbtcMock} from "test/mocks/WbtcMock.sol";
import {console} from "forge-std/console.sol";

contract MarketTest is Test {
    Market market;
    HelperConfig.NetworkConfig config;
    HelperConfig hconfig;
    address[] public priceFeeds;
    address[] public tokenaddresses;
    DefiCoin coin;
    address user;

    function setUp() public {
        Deploy deploy = new Deploy();

        (market, config, priceFeeds, tokenaddresses, coin) = deploy.run();

        user = makeAddr("user");
        vm.deal(user, 2000e18);
        WbtcMock(config.WbtcAddress).mint(user, 20e18);
        WethMock(config.WethAddress).mint(user, 30000e18);
    }

    function testIsfundsMinted() public {
        assert(IERC20(config.WbtcAddress).balanceOf(user) == 20e18);
        assert(IERC20(config.WethAddress).balanceOf(user) == 30000e18);
    }

    function testMarketPriceOfWeth() public {
        uint256 amount = market.getMarketPriceOfToken(
            config.WethAddress,
            config.WethpriceFeed,
            2e18
        );
        assert(amount == 6000e18);
    }

    function testcalculateAmountToMint() public {
        assert(market.calculateMaxAmountToMint(6000e18) == 4500);
    }

    function testDepositCollateralWorks() public {
        vm.startPrank(user);
        IERC20(config.WethAddress).approve(address(market), 2e18);
        market.DepositCollateralAndMintTokens(
            config.WethAddress,
            2e18,
            config.WethpriceFeed
        );
        assert(coin.balanceOf(user) > 0);
    }

    function testCalculateHealthFactor() public {
        vm.startPrank(user);
        IERC20(config.WethAddress).approve(address(market), 2e18);
        market.DepositCollateralAndMintTokens(
            config.WethAddress,
            2e18,
            config.WethpriceFeed
        );
        assert(market.calculateHealthFactor(user) == 1);
    }

    function testLiquidationWorks() public {}
}
