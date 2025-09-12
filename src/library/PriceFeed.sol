// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import {AggregatorV3Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPriceInUSD(address _priceFeed) public view returns (uint256) {
        (, int256 price, , , ) = AggregatorV3Interface(_priceFeed)
            .latestRoundData();
        // price already 8 decimals, so scale to 18 decimals
        return uint256(price) * 1e10;
    }

    function ConvertToUsdt(
        uint256 _amount,
        address _priceFeed
    ) public view returns (uint256) {
        uint256 price = getPriceInUSD(_priceFeed);
        // _amount is 18 decimals (ERC20), price is 18 decimals → result also 18 decimals
        return (_amount * price) / 1e18;
    }
}
