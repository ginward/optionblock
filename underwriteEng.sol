pragma solidity ^0.4.24;

/*
 *  The Option Underwriting Engine on Ethereum
 *  Author: Jinhua Wang 
 *  Apache License
 *  Version 2.0, January 2004
 *  http://www.apache.org/licenses/
 */

import "https://github.com/ginward/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol"; //import the safe math library
import "https://github.com/ginward/rbt-solidity/blob/master/contracts/RedBlackTree.sol" //import the red black tree


contract underwriteEng{
	uint constant contract_size = 100; //the number of stocks underlying the contract
	uint constant maturity_date = 20180701; //the maturity date should be in YYYYMMDD 
	uint constant strike = 200; //the strike price of the option contract
	string constant ticker = "AAPL"; //the apple sticker

	mapping (address => bid) bidorders;
	mapping (address => ask) askorders;

	uint64 orderid=0; //the unique order id
	using SafeMath for uint64;

	struct bid {
		//the bid object 
		uint price; 
		uint volume;
		uint timestamp;
		uint64 id; //id of the transaction
	}

	struct ask {
		//the ask object
		uint price; 
		uint volume;
		uint timestamp;
		uint64 id; //id of the transaction
	}

	//the red black tree structures 
	using RedBlackTree for RedBlackTree.Tree;
	RedBlackTree.Tree AskOrderBook;
	RedBlackTree.Tree BidOrderBook;

	function placeBid(uint p) returns (bool){
		/*
         * Function to place bid order
         * One address can only place one bid
		 */
		bid memory bidObj; 
		bidObj.price=p;
		bidObj.timestamp=now;
		orderid=newOrderID();
		bidObj.id=orderid;
		bidorders[msg.sender]=bidObj;
		BidOrderBook.insert(orderid,p);
	}

	function placeAsk(uint p) returns (bool){
		/*
		 * Function to place ask order
		 * One address can only place one ask
		 */
		ask memory askObj;
		askObj.price=p;
		askObj.timestamp=now;
		orderid=newOrderID();
		askObj.id=orderid;
		askorders[msg.sender]=askObj;
		AskOrderBook.insert(orderid,p);
	}
	
	function cancelBid() returns (bool){
		add=msg.sender;
	}

	function cancelAsk() returns (bool){
		add=msg.sender;
	}

	function newOrderID() returns (uint64){
		orderid=orderid.add(1);
		return orderid;
	}

}