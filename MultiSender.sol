// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract MultiSender {
    bool private locked;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed amount
    );

    event TransferError(
        address indexed from,
        address indexed to,
        uint256 indexed amount
    );

    event TransferERC721Error(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    modifier nonReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }

    modifier matchReceiver(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) {
        require(recipients.length > 0, "Recipients is empty");
        require(
            recipients.length == amounts.length,
            "Recipients not match amounts"
        );
        _;
    }

    /**
     * @dev Transfer ethers to multi sender
     * Emit an {Transfer} event when transferred success
     *
     * @param recipients address[] of recipients
     * @param amounts List of amount
     */
    function multiSendEth(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) public payable nonReentrant matchReceiver(recipients, amounts) {
        // send
        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] != address(0)) {
                (bool success, ) = payable(recipients[i]).call{
                    value: amounts[i]
                }("");

                if (success) {
                    emit Transfer(msg.sender, recipients[i], amounts[i]);
                } else {
                    emit TransferError(msg.sender, recipients[i], amounts[i]);
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
        address[] calldata recipients,
        uint256[] calldata amounts
    ) public matchReceiver(recipients, amounts) {
        address from = msg.sender;
        IERC20 erc20 = IERC20(token);

        // send
        for (uint256 i = 0; i < recipients.length; i++) {
            try
                erc20.transferFrom(from, recipients[i], amounts[i])
            {} catch Error(string memory reason) {
                emit TransferError(msg.sender, recipients[i], amounts[i]);
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
        address[] calldata recipients,
        uint256[] calldata ids
    ) public {
        require(recipients.length > 0, "Recipients is empty");
        require(
            recipients.length == ids.length,
            "Recipients not match token ids"
        );

        address from = msg.sender;
        IERC721 erc721 = IERC721(token);

        for (uint256 i = 0; i < recipients.length; i++) {
            try
                erc721.safeTransferFrom(from, recipients[i], ids[i])
            {} catch Error(string memory reason) {
                emit TransferERC721Error(msg.sender, recipients[i], ids[i]);
            }
        }
    }
}
