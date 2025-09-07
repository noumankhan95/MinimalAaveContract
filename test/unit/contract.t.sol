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
import {MockV3Aggregator} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/tests/MockV3Aggregator.sol";

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
        assert(market.calculateMaxAmountToMint(6000e18) == 4500e18);
    }

    function testDepositCollateralWorks() public {
        vm.startPrank(user);
        IERC20(config.WethAddress).approve(address(market), 2e18);
        market.DepositCollateralAndMintTokens(
            config.WethAddress,
            2e18,
            config.WethpriceFeed,
            2e18
        );
        assert(coin.balanceOf(user) > 0);
    }

    function testCalculateHealthFactor() public {
        vm.startPrank(user);
        IERC20(config.WethAddress).approve(address(market), 2e18);
        market.DepositCollateralAndMintTokens(
            config.WethAddress,
            2e18,
            config.WethpriceFeed,
            2e18
        );

        assert(market.calculateHealthFactor(user) == 1);
    }

    function testLiquidationWorks() public {
        vm.startPrank(user);
        IERC20(config.WethAddress).approve(address(market), 2e18);
        market.DepositCollateralAndMintTokens(
            config.WethAddress,
            2e18,
            config.WethpriceFeed,
            2e18
        );

        MockV3Aggregator(config.WethpriceFeed).updateAnswer(2000e10);
        vm.warp(block.timestamp + 1);

        vm.stopPrank();
        address liquidator = makeAddr("liquidator");
        WethMock(config.WethAddress).mint(liquidator, 2000e18);
        vm.startPrank(liquidator);
        IERC20(config.WethAddress).approve(address(market), 10e18);

        market.DepositCollateralAndMintTokens(
            config.WethAddress,
            10e18,
            config.WethpriceFeed,
            2e18
        );

        console.log(
            IERC20(config.WethAddress).balanceOf(liquidator),
            " Before "
        );

        market.liquidate(
            user,
            config.WethAddress,
            IERC20(coin).balanceOf(user)
        );
        console.log(IERC20(config.WethAddress).balanceOf(liquidator), " After");

        vm.stopPrank();
    }
}
