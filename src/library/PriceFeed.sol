// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import {AggregatorV3Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPriceInUSD(
        uint256 _amount,
        address _priceFeed
    ) internal returns (uint256) {
        (, int256 price, , , ) = AggregatorV3Interface(_priceFeed)
            .latestRoundData();

        return uint256(price * 1e10);
    }

    function ConvertToUsdt(
        uint256 _amount,
        address _priceFeed
    ) public returns (uint256) {
        return (getPriceInUSD(_amount, _priceFeed) * _amount) / 1e18;
    }
}
