//SPDX-License-Identifier:MIT

pragma solidity ^0.8.20;

import {PriceConverter} from "./library/PriceFeed.sol";

contract Market {
    //Errors
    error Market__PriceFeedsAndCollateralArraysUnequal();
    using PriceConverter for uint256;
    address[] public s_priceFeeds;
    address[] public s_collateralContracts;

    uint256 constant DIVISOR = 1e18;
    uint256 constant LTV = 75;
    mapping(address => mapping(address => uint256)) s_senderToCollateral;
    mapping(address => address) s_tokenToPriceFeed;
    //Modifiers
    modifier _isAllowedToken(
        address[] memory _priceFeeds,
        address[] memory _collateralContracts
    ) {
        if (_priceFeeds.length != _collateralContracts.length) {
            revert Market__PriceFeedsAndCollateralArraysUnequal();
        }
        _;
    }

    constructor(
        address[] memory _priceFeeds,
        address[] memory _collateralContracts
    ) _isAllowedToken(_priceFeeds, _collateralContracts) {
        s_priceFeeds = _priceFeeds;
        _collateralContracts = _collateralContracts;
        for (uint i = 0; i < _priceFeeds.length; i++) {
            s_tokenToPriceFeed[_collateralContracts[i]] = _priceFeeds[i];
        }
    }

    //Core Logic

    function DepositCollateralAndMintTokens(
        address tokenCollateral
    ) public payable {
        depositCollateral(msg.value, msg.sender, tokenCollateral);
    }

    function depositCollateral(
        uint256 _amount,
        address sender,
        address _tokenCollateral
    ) internal {
        s_senderToCollateral[sender][_tokenCollateral] += _amount;
    }

    function MintTokens(
        uint256 _amount,
        address sender,
        address _tokenCollateral
    ) internal {}

    function getMarketPriceOfToken(
        address _token,
        uint256 _amount
    ) internal returns (uint256) {
        uint256 _usdtValue = _amount.ConvertToUsdt(_token);
        uint256 _totalAmount = (_amount * _usdtValue) / DIVISOR;

        return _totalAmount;
    }
}
