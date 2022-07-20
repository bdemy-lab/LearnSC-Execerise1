// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "hardhat/console.sol";

contract MultiSender {
    using SafeMath for uint256;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed amount
    );

    /**
     * @dev Transfer ethers to multi sender
     * Emit an {Transfer} event when transferred success
     *
     * @param recipients address[] of recipients
     * @param amounts List of amount
     */
    function multiSendEth(
        address payable[] memory recipients,
        uint256[] memory amounts
    ) public payable {
        require(recipients.length > 0, "Recipients is empty");
        require(
            recipients.length == amounts.length,
            "Recipients not match token ids"
        );

        uint256 totalAmount = 0;

        // calculate total amount
        for (uint256 i = 0; i < amounts.length; i++) {
            require(amounts[i] > 0);
            totalAmount = totalAmount.add(amounts[i]);
        }

        // check msg.value at least total amount
        require(totalAmount <= msg.value, "Not enough amount");

        // send
        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] != address(0)) {
                bool success = recipients[i].send(amounts[i]);

                if (success) {
                    emit Transfer(msg.sender, recipients[i], amounts[i]);
                }
            }
        }
    }

    /**
     * @dev Transfer ERC20 token to multi sender
     * Emit an {Transfer} event when transferred success
     *
     * @param token address of ERC20 contract
     * @param recipients address[] of recipients
     * @param amounts List of amount
     */
    function multiSendERC20(
        address token,
        address[] memory recipients,
        uint256[] memory amounts
    ) public {
        require(recipients.length > 0, "Recipients is empty");
        require(
            recipients.length == amounts.length,
            "Recipients not match amounts"
        );

        address from = msg.sender;
        IERC20 erc20 = IERC20(token);
        uint256 totalAmount = 0;
        uint256 allowance = 0;
        uint256 balance = 0;

        // get allownce
        try erc20.allowance(from, address(this)) returns (uint256 amount) {
            allowance = amount;
            console.log("Allowance: ", allowance);
        } catch Error(string memory reason) {
            console.log("Error: ", reason);
        }

        // get sender balance
        try erc20.balanceOf(from) returns (uint256 amount) {
            balance = amount;
        } catch Error(string memory reason) {
            console.log("Error: ", reason);
        }

        // calculate total amount
        for (uint256 i = 0; i < amounts.length; i++) {
            require(amounts[i] > 0);
            totalAmount = totalAmount.add(amounts[i]);
        }

        // check allowance and balance at least total amount
        require(totalAmount <= allowance, "Not enough allowance");
        require(totalAmount <= balance, "Not enough balance");

        // send
        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] != address(0)) {
                try
                    erc20.transferFrom(from, recipients[i], amounts[i])
                {} catch Error(string memory reason) {
                    console.log("Error: ", reason);
                }
            }
        }
    }

    /**
     * @dev Transfer ERC721 token to multi sender
     * Emit an {Transfer} event when transferred success
     *
     * @param token address of ERC721 contract
     * @param recipients address[] of recipients
     * @param ids List of token id
     */
    function multiSendERC721(
        address token,
        address[] memory recipients,
        uint256[] memory ids
    ) public {
        require(recipients.length > 0, "Recipients is empty");
        require(
            recipients.length == ids.length,
            "Recipients not match token ids"
        );

        address from = msg.sender;
        IERC721 erc721 = IERC721(token);

        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] != address(0)) {
                try
                    erc721.safeTransferFrom(from, recipients[i], ids[i])
                {} catch Error(string memory reason) {
                    console.log("Error: ", reason);
                }
            }
        }
    }
}
