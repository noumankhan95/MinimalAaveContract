//SPDX-License-Identifier:MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {DefiCoin} from "../src/DefiCoin.sol";
import {Market} from "../src/Market.sol";

contract Deploy is Script {
    Market market;
    HelperConfig.NetworkConfig config;
    HelperConfig hconfig;
    address[] public priceFeeds;
    address[] public tokenaddresses;

    function run()
        public
        returns (
            Market,
            HelperConfig.NetworkConfig memory,
            address[] memory,
            address[] memory,
            DefiCoin
        )
    {
        hconfig = new HelperConfig();
        config = hconfig.getChainConfig(block.chainid);
        vm.startBroadcast(config.account);
        DefiCoin defiCoin = new DefiCoin();
        priceFeeds = [config.WethpriceFeed, config.WbtcpriceFeed];
        tokenaddresses = [config.WethAddress, config.WbtcAddress];
        market = new Market(priceFeeds, tokenaddresses, defiCoin);
        defiCoin.transferOwnership(address(market));
        vm.stopBroadcast();
        return (market, config, priceFeeds, tokenaddresses, defiCoin);
    }
}
