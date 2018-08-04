pragma solidity ^0.4.24;

/*
 *  The Option Underwriting Engine on Ethereum
 *  In this version, a owner can have only one bid/ask or option contracts
 *  Author: Jinhua Wang 
 *  Apache License
 *  Version 2.0, January 2004
 *  http://www.apache.org/licenses/
 */

import "github.com/oraclize/ethereum-api/oraclizeAPI.sol"; //import the oraclize api
import "https://github.com/ginward/openzeppelin-solidity/contracts/math/SafeMath.sol"; //import the safe math library
import "https://github.com/ginward/openzeppelin-solidity/contracts/math/SafeMath64.sol"; //import the safe math library
import "https://github.com/ginward/rbt-solidity/contracts/RedBlackTree.sol"; //import the red black tree

contract exchange is usingOraclize{

	using SafeMath for uint;
	using SafeMath64 for uint64;
	mapping (address => uint) balance; //the balance account for all traders
	mapping (address => uint) marginBalance; //the balance of margin account. frozen unless canceled order

	uint constant contract_size = 100; //the number of stocks underlying the contract. Uint is 1 cent USD. 100 cents = 1USD
	uint constant maturity_date = 20180701; //the maturity date should be in YYYYMMDD 
	uint constant strike = 200; //the strike price of the option contract, in USD
	string constant ticker = "AAPL"; //the apple ticker

	uint64 nodeid_bid=1; //the unique node id which maps to node that contains the order information for bid 
	uint64 nodeid_ask=1; //the unique node id which maps to node that contains the order information for ask

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
		marginBalance[msg.sender].add(m);
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
		 if (maxbid_id==0){
		 	revert();
		 }
		 RedBlackTree.Item memory maxbid_item=BidOrderBook.items[maxbid_id];
		 uint maxprice=maxbid_item.value; 
		 uint64 minask_id=AskOrderBook.getMinimum();
		 if(minask_id==0){
		 	revert();
		 }
		 RedBlackTree.Item memory minask_item=AskOrderBook.items[minask_id];
		 uint minprice=minask_item.value; 

		 //check if the orderbook crosses
		 if (minprice<maxprice){

		 	bid[] bidArr=bidnodes[maxbid_id];
		 	ask[] askArr=asknodes[minask_id];
		 	if (bidArr.length==0){
		 		BidOrderBook.remove(maxbid_id);
		 		//could have been a recursive call to matchOrders. but considering it is not a good practice and could burn the money,
		 		//did't implement it
		 		revert();
		 	}
		 	if (askArr.length==0){
		 		AskOrderBook.remove(minask_id);
		 		revert();
		 	}
		 	bid bid_order=bidArr[0];
		 	ask ask_order=askArr[0];
		 	//the orderbook crosses, execute the orders
		 	option memory opt;
		 	opt.long=bid_order.owner;
		 	opt.short=ask_order.owner;
		 	//check if the option owners still have orders outstanding
		 	if(optionOwners[opt.long].length!=0){
		 		//delete the bid 
		 		delete bidArr[0];
		 		revert();
		 	}
		 	if(optionOwners[opt.short].length!=0){
		 		//delete the ask
		 		delete askArr[0];
		 		revert();
		 	}
		 	//the bid volume
		 	uint vol_bid=bid_order.volume;
		 	//the ask volume
		 	uint vol_ask=ask_order.volume;

			if(vol_bid==vol_ask) {
				//when bid volume is equal to ask volume
		 		opt.volume=vol_ask; 
		 		opt.margin=ask_order.margin;
		 		opt.timestamp=now;
		 		//if the bid or ask array is empty, should delete the array
		 		if (bidArr.length==0) {
		 			delete bidnodes[maxbid_id];
		 			//delete the element in the mapping
		 			delete bidorders[bid_order.owner];
		 			//delete the element in the tree 
		 			BidOrderBook.remove(maxbid_id);
		 		} else {
		 			//clear the outstanding bid order
		 			delete bidArr[0];
		 		}
		 		if (askArr.length==0){
		 			delete asknodes[minask_id];
		 			delete askorders[ask_order.owner];
		 			AskOrderBook.remove(minask_id);
		 		} else {
		 			//clean the outstanding ask order 
		 			delete askArr[0];
		 		}
		 		
		 	}
		 	else if (vol_bid>vol_ask){
		 		//bid volume > ask volume
		 		opt.volume=vol_ask;
		 		opt.margin=ask_order.margin;
		 		opt.timestamp=now; 
		 		//keep part of the bid order outstanding
		 		bidArr[0].volume=bidArr[0].volume.sub(vol_ask);
		 		//clear the entire array if the ask array is 0 
		 		if (askArr.length==0){
		 			delete asknodes[minask_id];
		 			delete askorders[ask_order.owner];
		 			AskOrderBook.remove(minask_id);		 			
		 		} else {
			 		//clear the outstanding ask order 
			 		delete askArr[0];
		 		}
		 	}
		 	else{
		 		//ask volume > bid volume
		 		opt.volume=vol_bid;
		 		opt.margin=ask_order.margin; 
		 		opt.timestamp=now;
		 		//keep part of the ask order outstanding 
		 		askArr[0].volume=askArr[0].volume.sub(vol_bid);
		 		if (bidArr.length==0){
		 			delete bidnodes[maxbid_id];
		 			//delete the element in the mapping
		 			delete bidorders[bid_order.owner];
		 			//delete the element in the tree 
		 			BidOrderBook.remove(maxbid_id);		 			
		 		} else {
		 			//clear the outstanding bid order
		 			delete bidArr[0];		 			
		 		}
		 	}
		 	bytes32 hashOpt;
		 	//hash the option contract and push it into the map of all options
		 	hashOpt=keccak256(opt.long, opt.short, opt.volume, opt.margin, opt.timestamp);
		 	options[hashOpt]=opt;
		 	//keep track of who owns the option
		 	optionOwners[opt.long]=hashOpt;
		 	optionOwners[opt.short]=hashOpt;
		 }
	}

	function cancelBid() public{
		//the node id
		uint64 id=bidorders[msg.sender];
	 	bid[] bidArr=bidnodes[id];
	 	//delete from orderbook 
	 	for (uint i=0;i<bidArr.length;i++){
	 		bid bid_order=bidArr[i];
	 		if (bid_order.owner==msg.sender){
	 			delete bidArr[i];
	 		}
	 	}
		if (bidnodes[id].length==0){
			BidOrderBook.remove(id);
		}
		bidorders[msg.sender]=0;//reset the bidorders 
	}

	function cancelAsk() public{
		uint marginOrder=0;
		//the node id 
		uint64 id=askorders[msg.sender];
		ask []askArr=asknodes[id];
		//delete from orderbook
		for (uint i=0;i<askArr.length;i++){
			ask ask_order=askArr[i];
			if (ask_order.owner==msg.sender){
				marginOrder=ask_order.margin;
				delete askArr[i];
			}
		}
		//recover the margin value
		marginBalance[msg.sender].sub(marginOrder);
		balance[msg.sender].add(marginOrder);
		delete asknodes[id]; //delete from orderbook
		if(asknodes[id].length==0){
			AskOrderBook.remove(id);
		}
		askorders[msg.sender]=0;
	}

	function mature() public{
		//this function is called when the contract matures

	}

}