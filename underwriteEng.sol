pragma solidity ^0.4.24;

/*
 *  The Option Underwriting Engine on Ethereum
 *  In this version, a owner can have only one bid/ask or option contracts
 *  Author: Jinhua Wang 
 *  Apache License
 *  Version 2.0, January 2004
 *  http://www.apache.org/licenses/
 */

import "https://github.com/ginward/openzeppelin-solidity/contracts/math/SafeMath.sol"; //import the safe math library
import "https://github.com/ginward/openzeppelin-solidity/contracts/math/SafeMath64.sol"; //import the safe math library
import "https://github.com/ginward/rbt-solidity/contracts/RedBlackTree.sol"; //import the red black tree

contract underwriteEng{

	using SafeMath for uint;
	using SafeMath64 for uint64;
	mapping (address => uint) margin; //the balance of margin. cannot be withdrawn. 
	mapping (address => uint) balance; //the balance account for all traders

	uint constant contract_size = 100; //the number of stocks underlying the contract. Uint is 1 cent USD. 100 cents = 1USD
	uint constant maturity_date = 20180701; //the maturity date should be in YYYYMMDD 
	uint constant strike = 200; //the strike price of the option contract, in USD
	string constant ticker = "AAPL"; //the apple ticker

	uint64 nodeid_bid=0; //the unique node id which maps to node that contains the order information for bid 
	uint64 nodeid_ask=0; //the unique node id which maps to node that contains the order information for ask

	mapping (address => uint64) bidorders; //map each owner to a tree node
	mapping (address => uint64) askorders;

	mapping (uint64 => bid[]) bidnodes; //map each tree node to bid orders
	mapping (uint64 => ask[]) asknodes; //map each tree node to ask orders

	mapping (address => bytes32) optionOwners; //map to the options. one owner can have only one option.
	mapping (bytes32 => option) options; //option details

	struct bid {
		//the bid object 
		uint price; 
		uint volume;
		uint timestamp;
		address owner;
	}

	struct ask {
		//the ask object
		uint margin; //when the trader asks, he needs to provide a margin 
		uint price;
		uint volume;
		uint timestamp;
		address owner; 
	}

	struct option {
		address long;
		address short; 
		uint volume;
		uint margin; 
		uint timestamp;
	}

	//the red black tree structures 
	using RedBlackTree for RedBlackTree.Tree;
	RedBlackTree.Tree AskOrderBook;
	RedBlackTree.Tree BidOrderBook;

	function placeBid() public payable{
		/*
         * Function to place bid order
         * One address can only place one bid
		 */

		 //first check if the sender already has an order. if so, he is not allowed to send another one until this one gets executed
		 //expect to upgrade to multiple orders in version 2.0
		if (bidorders[msg.sender]!=0||askorders[msg.sender]!=0||optionOwners[msg.sender]!=0){
			revert();
		}

		uint p=msg.value;
		//add the money to balance
		balance[msg.sender].add(p);
		bid memory bidObj; 
		bidObj.price=p;
		bidObj.timestamp=now;
		bidObj.owner=msg.sender;
		nodeid_bid=nodeid_bid.add(1);
		bidorders[msg.sender]=nodeid_bid;
		BidOrderBook.insert(nodeid_bid,p);
		bidnodes[nodeid_bid].push(bidObj);
	}

	function placeAsk(uint p) public payable{
		/*
		 * Function to place ask order
		 * One address can only place one ask
		 */

		//check if the sender already has an order
		if(bidorders[msg.sender]!=0||askorders[msg.sender]!=0||optionOwners[msg.sender]!=0){
			revert();
		}

		uint m=msg.value; //the money sent alone is the margin
		//add the money to margin 
		margin[msg.sender].add(m);
		ask memory askObj;
		askObj.margin=m;
		askObj.price=p; //the ask price is passed in as a parameter
		askObj.timestamp=now;
		askObj.owner=msg.sender;
		nodeid_ask=nodeid_ask.add(1);
		askorders[msg.sender]=nodeid_ask;
		AskOrderBook.insert(nodeid_ask,p);
		asknodes[nodeid_ask].push(askObj);
	}
	
	function matchOrders() private {
		/*
  	 	 * Function to match the orders in the orderbook
		 */
		 uint64 maxbid_id=BidOrderBook.getMaximum();
		 RedBlackTree.Item memory maxbid_item=BidOrderBook.items[maxbid_id];
		 uint maxprice=maxbid_item.value; 
		 uint64 minask_id=AskOrderBook.getMinimum();
		 RedBlackTree.Item memory minask_item=AskOrderBook.items[minask_id];
		 uint minprice=minask_item.value; 

		 //check if the orderbook crosses
		 if (minprice<maxprice){

		 	//the orderbook crosses, execute the orders
		 	option memory opt;

		 }
	}

	function cancelBid() public{
		uint64 id=bidorders[msg.sender];

	}

	function cancelAsk() public{
		uint64 id=askorders[msg.sender];
	}

}