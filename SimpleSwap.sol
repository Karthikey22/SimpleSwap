// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorInterface.sol";

// Simple swapping contract for Eth and Dai

contract SimpleSwap{

     AggregatorInterface internal priceFeed;
    constructor() public {
        priceFeed = AggregatorInterface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    }

    event AddsLiquidity(address indexed provider,uint indexed Eth_amount,uint indexed Dai_amount);
    event RemoveLiquidity(address indexed provider,uint indexed Eth_amount,uint indexed Dai_amount);
    event Transfer(address indexed from,address indexed t0,uint indexed amount);
    event DaiPurchase(address indexed buyer,uint indexed EthSold,uint DaiBought);
    event EthPurchase(address indexed buyer,uint indexed DaiSold,uint EthBought);

    address public DaiToken=0x6B175474E89094C44Da98b954EedeAC495271d0F;
    mapping(address=>uint) LPDai; //Dai liquidity Pool
    mapping(address=>uint) LPEth; // Eth liquidity pool


    function AddLiquidity(uint Dai_amount,uint Eth_Amount)public payable{
        
        emit AddsLiquidity(msg.sender,Eth_Amount,Dai_amount);
        DaiToken.transferFrom(msg.sender,address(this),Dai_amount);
        LPDai[msg.sender]+=Dai_amount;
        address(this).send(Eth_Amount);
        LPEth[msg.sender]+=Eth_Amount;

    }

    function removeLiquidity(uint Dai_amount,uint Eth_Amount)public payable{
        if(LPDai[msg.sender]>0 && LPEth[msg.sender]>0){
            
            if(Dai_amount<=LPDai[msg.sender]&&Eth_Amount<=LPEth[msg.sender]){

                DaiToken.transferFrom(address(this),msg.sender,Dai_amount);
                address(this).send(Eth_Amount);
                LPEth[msg.sender]-=Eth_Amount;
                LPDai[msg.sender]-=Dai_amount;
            }
            else{
                return "don't have that much liquidity for you";
            }
            
        }
        else{
            return "amount must be greater than 0"; 
        }

    }

    function SwapEthtoDai(uint Eth_amount) public payable{ 
        uint EDCount;
        uint DaiBalance=address(this).balanceOf(DaiToken);
        uint EthPrice=priceFeed.latestAnswer(); //fetching live Eth-USd price;
        uint DaiToBeBought=EthPrice*Eth_amount;
        assert(DaiBalance>DaiToBeBought,"Not enough funds in pool");
        uint total= Eth_amount + 0.0014 ether; // Swapping fees.
        address(this).send(total);
        DaiToken.transferFrom(address(this),msg.sender,DaiToBeBought);
        
        emit DaiPurchase(msg.sender,Eth_amount,DaiToBeBought);
        

    }

    function SwapDaitoEth(uint Dai_amount) public payable{ 
        uint Ethbalance=address(this).balance;
        uint EthPrice=priceFeed.latestAnswer();
        uint EthToBeBought=EthPrice/Dai_amount;
        assert(Ethbalance>EthToBeBought,"Not enough funds in pool");
        DaiToken.transferFrom(address(this),msg.sender,EthToBeBought);
        msg.sender.transfer(EthToBeBought);
        emit DaiPurchase(msg.sender,Dai_amount,EthToBeBought);

    }

    

}