//SPDX-License-Identifier:MIT

pragma solidity ^0.8.20;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract DefiCoin is ERC20, Ownable {
    constructor() ERC20("Defi Coin", "DFI") Ownable(msg.sender) {}

    function mint(address _account, uint256 _amount) public onlyOwner {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) public onlyOwner {
        _burn(_account, _amount);
    }
}
