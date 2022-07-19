// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mintable is ERC20 {
    address private _contractOwner;

    constructor() ERC20("ERC20", "TTT") {
        _contractOwner = msg.sender;
    }

    function mint(address account, uint256 amount) public virtual returns (bool) {
        require(_contractOwner == msg.sender, "Only contract owner!");
        require(amount > 0, "Please input an amount greater than 0");
        _mint(account, amount);
        return true;
    }
}
