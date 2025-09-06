//SPDX-License-Identifier:MIT

pragma solidity ^0.8.20;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract DefiCoin is ERC20 {
    constructor() ERC20("Defi Coin", "DFI") {}

    function mint(address _account, uint256 _amount) public {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) public {
        _burn(_account, _amount);
    }
}
