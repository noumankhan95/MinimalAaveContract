//SPDX-License-Identifier:MIT

pragma solidity ^0.8.20;

import {PriceConverter} from "./library/PriceFeed.sol";
import {DefiCoin} from "./DefiCoin.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Market {
    //Errors
    error Market__PriceFeedsAndCollateralArraysUnequal();
    using PriceConverter for uint256;
    address[] public s_priceFeeds;
    address[] public s_collateralContracts;

    uint256 constant DIVISOR = 1e18;
    uint256 constant LTV = 75;
    uint256 constant PERCENT = 100;
    mapping(address => mapping(address => uint256)) s_senderToCollateral;
    mapping(address => address) s_tokenToPriceFeed;
    DefiCoin internal immutable deficoin;
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
        address[] memory _collateralContracts,
        DefiCoin _defiCoin
    ) _isAllowedToken(_priceFeeds, _collateralContracts) {
        s_priceFeeds = _priceFeeds;
        _collateralContracts = _collateralContracts;
        for (uint i = 0; i < _priceFeeds.length; i++) {
            s_tokenToPriceFeed[_collateralContracts[i]] = _priceFeeds[i];
        }
        deficoin = _defiCoin;
    }

    //Core Logic

    function DepositCollateralAndMintTokens(
        address _tokenCollateral
    ) public payable {
        depositCollateral(msg.value, msg.sender, _tokenCollateral);
        MintTokens(msg.value, msg.sender, _tokenCollateral);
    }

    function depositCollateral(
        uint256 _amount,
        address sender,
        address _tokenCollateral
    ) internal {
        s_senderToCollateral[sender][_tokenCollateral] += _amount;
        bool success = IERC20(_tokenCollateral).transferFrom(
            sender,
            address(this),
            _amount
        );
        require(success, "Transfer Failed");
    }

    function MintTokens(
        uint256 _amount,
        address sender,
        address _tokenCollateral
    ) internal {
        uint256 _price = getMarketPriceOfToken(_tokenCollateral, _amount);
        uint256 toMint = calculateAmountToMint(_price);

        deficoin.mint(sender, toMint);
    }

    function getMarketPriceOfToken(
        address _tokenAddress,
        uint256 _amount
    ) internal returns (uint256) {
        uint256 _usdtValue = _amount.ConvertToUsdt(_tokenAddress);
        uint256 _totalAmount = (_amount * _usdtValue) / DIVISOR;

        return _totalAmount;
    }

    function calculateAmountToMint(
        uint256 _amount
    ) public pure returns (uint256) {
        return ((_amount / DIVISOR) * LTV) / PERCENT;
    }
}
