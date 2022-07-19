// SPDX-License-Identifier: MIT
// Thai_Pham Contracts

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

contract multiSender {
    using SafeMath for uint256;
    event Multisended(uint256 total, address tokenAddress);
    event SendFail(address tokenAddress, address sender, address receiver,string error);


    constructor() {}

    function sendERC20(
        address token,
        address[] memory _receiver,
        uint256[] memory _amount
    ) private  returns (bool) {
        uint256 totalSend = 0;
        IERC20 erc20Contract = IERC20(token);

        require(_receiver.length <= 100, "receiver list is overload! please give a list smaller than 100");
        require(_receiver.length == _amount.length, "lacking of amount infomation, please check again!");

        uint256 allowance = erc20Contract.allowance(msg.sender, address(this));

        require(allowance > 0, "please approve erc20 before send!"  );

        for (uint256 j = 0; j < _receiver.length; j++) {
            try erc20Contract.transferFrom(msg.sender, _receiver[j], _amount[j]) {
                totalSend += _amount[j];
            }
            catch Error(string memory reason ){

                emit SendFail(token , msg.sender, _receiver[j] , reason);
            }
            
        }         
        emit Multisended(totalSend, token);
        return true;
    }

    function sendEther(address[] memory _receiver, uint256[] memory _amount) private  returns (bool) {
            uint256 total = msg.value;
            require(total != uint(0), "don't have any ETH to send");

            require(_receiver.length <= 100, "receiver list is overload! please give a list smaller than 100");
            require(_receiver.length == _amount.length, "lacking of amount infomation, please check again!");
            
            for (uint256 i = 0; i < _receiver.length; i++) {
          
            
                try this._sendEther(_receiver[i],_amount[i]) {

                    total = total.sub(_amount[i]);
                    
                }  catch Error(string memory reason){

                    emit SendFail(address(0) , msg.sender,_receiver[i],reason);
                }                

            }
            
            //return remain eth to sender
            if(total != 0){
                (bool success) = payable(msg.sender).send(total);

                console.log("send changes back to sender");

                require(success == true,"transfer fail");

            }

            emit Multisended( msg.value - total, msg.sender);
        return true;
    }

    function sendERC721(
        address token,
        address[] memory _receiver,
        uint256[] memory _tokenID
    ) private returns (bool) {
        uint256 total = 0;
        IERC721 erc721Contract = IERC721(token);
        require(_receiver.length <= 100, "receiver list is overload! please give a list smaller than 100");
        require(_receiver.length == _tokenID.length, "lacking of amount infomation, please check again!");
        uint256 j = 0;
        for (; j < _receiver.length; j++) {
            try  erc721Contract.safeTransferFrom(msg.sender, _receiver[j], _tokenID[j]){
                total +=1;
            }
            catch Error(string memory reason){
               console.log(reason);
               emit SendFail(token , msg.sender,_receiver[j],reason);
            }
        }
        emit Multisended(total, token);
        return true;
    }

    function _sendEther(address receiver, uint256 amount) external{


       (bool success) = payable(receiver).send(amount);

       console.log(success);

       require(success == true,"transfer fail");

    }


    function multisender( 
        address token,
        address[] memory _receiver,
        uint256[] memory _tokenID,
        uint256[] memory _amount)external payable virtual returns (bool){
        require(_receiver.length <= 100, "receiver list is overload! please give a list smaller than 100");

        if( token == address(0) && _tokenID.length == 0) //ETH
        {

            sendEther(_receiver,_amount);           

        }else if(token != address(0) &&  _tokenID.length == 0)//ERC20
        {

            sendERC20(token,_receiver,_amount);
        
        } 
        else if(token != address(0) &&  _tokenID.length != 0 && _amount.length == 0 )//ERC721
        {
            sendERC721(token,_receiver,_tokenID);

        } else{
            revert("check your parameter!");
        }
        return true;
    }

    function getBalance()public view returns(uint256){
      return address(this).balance;  
    } 


}
