// SPDX-License-Identifier: MIT
// Thai_Pham Contracts

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";



contract multiSender is Ownable, ReentrancyGuard {
    event Multisended(uint256 total, address tokenAddress);
    event SendFail(address tokenAddress, address sender, address receiver);


    constructor() {}

    function sendERC20(
        address token,
        address[] calldata _receiver,
        uint256[] calldata _amount
    ) public  returns (bool) {
        uint256 totalSend = 0;
        IERC20 erc20Contract = IERC20(token);
        uint256 receiverLength = _receiver.length;   

        for (uint256 j; j < receiverLength; j++) {
            try erc20Contract.transferFrom(msg.sender, _receiver[j], _amount[j]) {
                totalSend += _amount[j];
            }
            catch {

                emit SendFail(token , msg.sender, _receiver[j]);
            }
            
        }         
        emit Multisended(totalSend, token);
        return true;
    }

    function sendEther(
        address[] calldata _receiver, 
        uint256[] calldata _amount
    ) public nonReentrant payable returns (bool) {
        uint256 total = msg.value;
        uint256 receiverLength = _receiver.length;   

        for (uint256 i; i < receiverLength; i++) {               
        
            try this._sendEther(_receiver[i],_amount[i]) {

                total = total -_amount[i];
                
            }  catch{

                emit SendFail(address(0) , msg.sender,_receiver[i]);
            }                

        }
        
        //return remain eth to sender
        if(total != 0){
            (bool success) = payable(msg.sender).send(total);

            require(success == true,"transfer fail");
        }

        emit Multisended( msg.value - total, msg.sender);
        return true;
    }

    function sendERC721(
        address token,
        address[] calldata _receiver,
        uint256[] calldata _tokenID
    ) public returns (bool) {
        uint256 total = 0;
        IERC721 erc721Contract = IERC721(token);
        uint256 receiverLength = _receiver.length;   
        
        for (uint256 j; j < receiverLength; j++) {
            try  erc721Contract.safeTransferFrom(msg.sender, _receiver[j], _tokenID[j]){
                total +=1;
            }
            catch {
               emit SendFail(token , msg.sender,_receiver[j]);
            }
        }
        emit Multisended(total, token);
        return true;
    }

    function _sendEther(address receiver, uint256 amount) external  {
        require(msg.sender == address(this), "can not call outside this contract");

       (bool success, ) =  payable(receiver).call{value: amount}("");

       require(success == true,"transfer fail");
    }


    function getBalance()public view returns(uint256){
      return address(this).balance;  
    } 


}
