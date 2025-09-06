//SPDX-License-Identifier:MIT

pragma solidity ^0.8.20;

import {PriceConverter} from "./library/PriceFeed.sol";
import {DefiCoin} from "./DefiCoin.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/console.sol";

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
    mapping(address => uint256) s_mintedDefi;
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
    modifier _isPriceFeedAndCollateralLengthEqual(
        address[] memory _priceFeeds,
        address[] memory _collateralContracts
    ) {
        require(
            _priceFeeds.length == _collateralContracts.length,
            "Collateral And PriceFeeds should be equal"
        );
        _;
    }

    constructor(
        address[] memory _priceFeeds,
        address[] memory _collateralContracts,
        DefiCoin _defiCoin
    )
        _isAllowedToken(_priceFeeds, _collateralContracts)
        _isPriceFeedAndCollateralLengthEqual(_priceFeeds, _collateralContracts)
    {
        s_priceFeeds = _priceFeeds;
        s_collateralContracts = _collateralContracts;
        for (uint i = 0; i < _priceFeeds.length; i++) {
            s_tokenToPriceFeed[_collateralContracts[i]] = _priceFeeds[i];
        }
        deficoin = _defiCoin;
    }

    //Core Logic

    function DepositCollateralAndMintTokens(
        address _tokenCollateral,
        uint256 _amount,
        address _priceFeed
    ) public payable {
        depositCollateral(_amount, msg.sender, _tokenCollateral);
        MintTokens(_amount, msg.sender, _tokenCollateral, _priceFeed);
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
        address _tokenCollateral,
        address _priceFeed
    ) internal {
        uint256 _price = getMarketPriceOfToken(
            _tokenCollateral,
            _priceFeed,
            _amount
        );
        uint256 toMint = calculateMaxAmountToMint(_price);
        s_mintedDefi[sender] += toMint;
        deficoin.mint(sender, toMint);
    }

    function redeemCollateralAndBurnTokens(
        address _collateralAddress,
        address _tokenPriceFeedAddress,
        address _user,
        uint256 _amount
    ) public {
        burnTokens(_user, _amount);
        redeemCollateral(_user, _user, _amount, _collateralAddress);
    }

    function redeemCollateral(
        address cfor,
        address to,
        uint256 _amount,
        address _collateralAddress
    ) public {
        require(
            s_senderToCollateral[cfor][_collateralAddress] >= _amount,
            "Not Enough Collateral"
        );
        s_senderToCollateral[cfor][_collateralAddress] -= _amount;
        bool success = IERC20(_collateralAddress).transfer(to, _amount);
        require(success, "Couldnt Transfer Collateral Back");
    }

    function burnTokens(address _user, uint256 _amount) public {
        deficoin.burn(_user, _amount);
        s_mintedDefi[_user] -= _amount;
    }

    function getMarketPriceOfToken(
        address _tokenAddress,
        address _priceFeedAddress,
        uint256 _amount
    ) public view returns (uint256) {
        return _amount.ConvertToUsdt(_priceFeedAddress);
    }

    function calculateMaxAmountToMint(
        uint256 _amount
    ) public pure returns (uint256) {
        return ((_amount / DIVISOR) * LTV) / PERCENT;
    }

    function calculateHealthFactor(
        address _user
    ) public view returns (uint256) {
        uint256 totalCollateral = calculateTotalCollateralInUSD(_user);
        uint256 collateral = calculateMaxAmountToMint(totalCollateral);
        uint256 healthFactor = collateral / s_mintedDefi[_user];
        return healthFactor;
    }

    function calculateTotalCollateralInUSD(
        address _user
    ) public view returns (uint256 totalCollateral) {
        for (uint i = 0; i < s_priceFeeds.length; i++) {
            totalCollateral += getMarketPriceOfToken(
                s_collateralContracts[i],
                s_priceFeeds[i],
                s_senderToCollateral[_user][s_collateralContracts[i]]
            );
        }
    }

    function liquidate(
        address _toLiquidate,
        address _collateralAddress,
        uint256 _debtToCover
    ) public {
        uint256 healthFactor = calculateHealthFactor(_toLiquidate);
        require(healthFactor < 1, "Cant Liquidate Healthy User");
        uint256 _amount = _debtToCover.ConvertToUsdt(_collateralAddress);
        uint256 bonus = ((((_amount / DIVISOR)) / (PERCENT)) * _amount);
        redeemCollateral(
            _toLiquidate,
            msg.sender,
            _amount + bonus,
            _collateralAddress
        );
        burnTokens(_toLiquidate, s_mintedDefi[_toLiquidate]);

        require(
            healthFactor > 1,
            "Liquidation doesnt improve the health factor"
        );
    }
}
