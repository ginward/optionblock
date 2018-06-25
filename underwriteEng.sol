pragma solidity ^0.4.24;

/*
 *  The Option Underwriting Engine on Ethereum
 *  Author: Jinhua Wang 
 *  Apache License
 *  Version 2.0, January 2004
 *  http://www.apache.org/licenses/
 */

import "https://github.com/ginward/openzeppelin-solidity/contracts/math/SafeMath64.sol"; //import the safe math library
import "https://github.com/ginward/rbt-solidity/contracts/RedBlackTree.sol"; //import the red black tree


contract underwriteEng{

	using SafeMath for uint64;
	mapping (address => uint) balance; //the balance account for all traders

	uint constant contract_size = 100; //the number of stocks underlying the contract
	uint constant maturity_date = 20180701; //the maturity date should be in YYYYMMDD 
	uint constant strike = 200; //the strike price of the option contract
	string constant ticker = "AAPL"; //the apple sticker

	mapping (address => bid) bidorders;
	mapping (address => ask) askorders;
	uint64 orderid=0; //the unique order id

	struct bid {
		//the bid object 
		uint price; 
		uint volume;
		uint timestamp;
		uint64 id; //id of the transaction
	}

	struct ask {
		//the ask object
		uint margin; //when the trader asks, he needs to provide a margin 
		uint price;
		uint volume;
		uint timestamp;
		uint64 id; //id of the transaction
	}

	//the red black tree structures 
	using RedBlackTree for RedBlackTree.Tree;
	RedBlackTree.Tree AskOrderBook;
	RedBlackTree.Tree BidOrderBook;

	function placeBid() public payable returns (bool){
		/*
         * Function to place bid order
         * One address can only place one bid
		 */
		uint p=msg.value;
		bid memory bidObj; 
		bidObj.price=p;
		bidObj.timestamp=now;
		orderid=newOrderID();
		bidObj.id=orderid;
		bidorders[msg.sender]=bidObj;
		BidOrderBook.insert(orderid,p);
	}

	function placeAsk(uint p) public payable returns (bool){
		/*
		 * Function to place ask order
		 * One address can only place one ask
		 */
		uint m=msg.value;
		ask memory askObj;
		askObj.margin=m;
		askObj.price=p;
		askObj.timestamp=now;
		orderid=newOrderID();
		askObj.id=orderid;
		askorders[msg.sender]=askObj;
		AskOrderBook.insert(orderid,p);
	}
	
	function cancelBid() public returns (bool){
		uint64 id=bidorders[msg.sender].id;

	}

	function cancelAsk() public returns (bool){
		uint64 id=askorders[msg.sender].id;
	}

	function newOrderID() private returns (uint64){
		uint64 newid=orderid.add(1);
		if (newid<orderid)
			//prevent order overflow
			revert("ID Overflow");
		orderid=newid;
		return orderid;
	}

}