pragma solidity ^0.4.24;

/*
 *  The Option Underwriting Engine on Ethereum
 *  Author: Jinhua Wang 
 *  Apache License
 *  Version 2.0, January 2004
 *  http://www.apache.org/licenses/
 */

import "https://github.com/ginward/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol"; //import the safe math library
import "https://github.com/ginward/solidity-examples/blob/master/heap.sol" //import the heap library to maintain a sorted price list

contract underwriteEng{
	uint constant contract_size = 100; //the number of stocks underlying the contract
	uint constant maturity_date = 20180701; //the maturity date should be in YYYYMMDD 
	uint constant strike = 200; //the strike price of the option contract
	string constant ticker = "AAPL"; //the apple sticker

	struct bid {
		//the bid object 
		uint price; 
		address bidder;
		uint timestamp;
	}

	struct ask {
		//the ask object
		uint price; 
		address asker;
		uint timestamp;
	}

	//the heap structures
	using MinHeap_impl[ask] for AskOrder[ask]; //ask orderbook is a minimum heap
	using MaxHeap_impl[bid] for BidOrder[bid]; //bid orderbook is a maximum heap


}