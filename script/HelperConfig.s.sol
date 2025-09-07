//SPDX-License-Identifier:MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MockV3AggregatorTest} from "../test/mocks/AggregatorV3Mock.sol";
import {WethMock} from "test/mocks/WethMock.sol";
import {WbtcMock} from "test/mocks/WbtcMock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address WethpriceFeed;
        address WbtcpriceFeed;
        address WethAddress;
        address WbtcAddress;
        address account;
    }
    mapping(uint256 => NetworkConfig) internal networkConfig;
    uint256 constant SEPOLIACHAINID = 11155111;
    uint256 constant ETHCHAINID = 1;
    uint256 constant ANVILCHAINID = 31337;

    constructor() {
        networkConfig[SEPOLIACHAINID] = getSepoliaEthConfig();
        networkConfig[ETHCHAINID] = getMainEthConfig();
        networkConfig[ANVILCHAINID] = getAnvilEthConfig();
    }

    function getChainConfig(
        uint256 chainId
    ) public view returns (NetworkConfig memory) {
        return networkConfig[chainId];
    }

    function getMainEthConfig() internal pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                WbtcAddress: address(0),
                WethAddress: address(0),
                WethpriceFeed: address(0),
                WbtcpriceFeed: address(0),
                account: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
            });
    }

    function getSepoliaEthConfig()
        internal
        pure
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                WbtcAddress: address(0),
                WethAddress: address(0),
                WethpriceFeed: address(0),
                WbtcpriceFeed: address(0),
                account: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
            });
    }

    function getAnvilEthConfig() internal returns (NetworkConfig memory) {
        MockV3AggregatorTest wethaggregator = new MockV3AggregatorTest(
            10,
            3000e10
        );
        MockV3AggregatorTest wbtcaggregator = new MockV3AggregatorTest(
            10,
            110000e10
        );
        WethMock weth = new WethMock();
        WbtcMock wbtc = new WbtcMock();
        return
            NetworkConfig({
                WbtcAddress: address(wbtc),
                WethAddress: address(weth),
                WethpriceFeed: address(wethaggregator),
                WbtcpriceFeed: address(wbtcaggregator),
                account: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
            });
    }
}
