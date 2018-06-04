pragma solidity ^0.4.0;

/*
 *  Author: Jinhua Wang 
 *  Apache License
 *  Version 2.0, January 2004
 *  http://www.apache.org/licenses/
 */

contract CallOpt{
	/*												
     * The call option contract
	 */
	 address public god; //the creator of the call option
	 address public buyer; //the buyer of the call option
	 address public seller; //the seller of the call option 
	 uint long; //the long money
	 bool long_satisfied;
	 uint short; //the short money
	 bool short_satisfied;
	 enum State { Inactive, Active, Mature }
	 State public state; 

	 uint strike; //the strike price, in USD

	 mapping (string => uint) balances; //the eth balances. 'Buyer' => Balance, 'Seller' => Balance
	 mapping (address => uint) public refund_balances; 

	 //transfer of ownership
	 bool buyer_transfer;
	 address buyer_transfer_add;
	 uint buyer_transfer_price;

	 bool seller_transfer;
	 address seller_transfer_add; 
	 uint seller_transfer_price;

	 function CallOpt(address initbuyer, address initseller, uint initstrike, uint longp, uint shortp) public {
	 	//the constructor sets the owner
	 	god=msg.sender;
	 	buyer=initbuyer;
	 	seller=initseller;
	 	strike=initstrike;
	 	long=longp;
	 	short=shortp;
	 	state=State.Inactive; //set the state to be inactive in the beginning
	 }

	 function activeContract() sudo {
	 	//the function to activate the contract 
	 	//only sudo user can call this function 
	 	if (!long_satisfied || !short_satisfied){
	 		revert();
	 	}
	 	state=State.Active;
	 }

	 function MatureContract(uint price, uint ex) sudo {
	 	uint eth_price;
	 	uint strike_price;
	 	uint hypo_proceeds;
	 	uint max_proceeds;
	 	uint proceeds;
	 	//perform the action when contract matures
	 	if (state==State.Inactive){
	 		revert();
	 	}
	 	//price is the current price, in usd 
	 	eth_price = price * ex;
	 	strike_price = price * ex;
	 	if (eth_price>strike_price){
	 		hypo_proceeds=eth_price-strike_price;
	 		max_proceeds=long+short;
	 		proceeds=min(hypo_proceeds,max_proceeds);
	 		refund_balances[buyer]+=proceeds;
	 	} else if (eth_price<strike_price){
	 		max_proceeds=long+short;
	 		refund_balances[seller]+=max_proceeds;
	 	}
	 }

	 function DeActiveContract() sudo {
	 	//Deactive contract 
	 	state=State.Inactive;
	 }

	 function initBuyerTransfer(uint target_price, address target_add) sudo {
	 	//sudo user initiate the buyer transfer process 
	 	buyer_transfer=true;
	 	buyer_transfer_add=target_add;
	 	buyer_transfer_price=target_price;
	 }

	 function initSellerTransfer(uint target_price, address target_add) sudo {
	 	//sudo user initiate the seller transfer process
	 	seller_transfer=true;
	 	seller_transfer_add=target_add;
	 	seller_transfer_price=target_price;
	 }

	 function buyerTransfer(address target) payable isVerifiedBuyer{
	 	uint infund;
	 	uint refund;
	 	require(
	 		buyer_transfer == true, "Not for sale at the moment!"
	 	);
	 	infund=msg.value;
	    if(infund<buyer_transfer_price){
	 		//not enough fund, revert transaction
	 		revert();
	 	}
	 	refund=infund - buyer_transfer_price; 
	 	if (refund>=0){
	 		refund_balances[target]+=refund;
	 	}
	 	//increase of balance of the fund of the old buyer
	 	refund_balances[buyer]+=buyer_transfer_price;
	 	buyer=target;
	 	buyer_transfer=false;
	 }

	 function sellerTransfer(address target) isVerifiedSeller payable{
	 	uint infund;
	 	uint refund;
	 	require(
	 		seller_transfer == true, "Not for sale at the moment!"
	 	);
	 	infund=msg.value;
	    if(infund<seller_transfer_price){
	 		//not enough fund, revert transaction
	 		revert();
	 	}
	 	refund=infund - seller_transfer_price;
	 	if (refund>=0){
	 		refund_balances[target]+=refund;
	 	}
	 	seller.transfer(seller_transfer_price);
	 	seller=target; 	
	 	seller_transfer=false;
	 }

	//withdraw funds in the balance
    function withdraw() public returns (bool) {
        uint amount = refund_balances[msg.sender];
        if (amount > 0) {
            // It is important to set this to zero because the recipient
            // can call this function again as part of the receiving call
            // before `send` returns.
            refund_balances[msg.sender] = 0;

            if (!msg.sender.send(amount)) {
                // No need to call throw here, just reset the amount owing
                refund_balances[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

	 //the fallback function to save money sent to here by mistake
	 function() public payable{
	 	address sender;
	 	uint refund;
	 	sender=msg.sender; //get the address of the sender of the message
	 	if (sender==buyer){
		 	if (long>msg.value){
		 		revert();
		 	}
		 	refund=msg.value-long;
		 	refund_balances[msg.sender]+=refund;
		 	long_satisfied=true;
	 	}
	 	else if (sender==seller){
		 	if (short>msg.value){
		 		revert();
		 	}
		 	refund=msg.value-short;
		 	refund_balances[msg.sender]+=refund;
		 	short_satisfied=true;
	 	}
	 	else {
	 		revert();
	 	}
	 }

	 modifier sudo{
	 	//function to check if the caller of a function is the owner
	 	require(
	 		msg.sender == god, "You are not God."
	 	);
	 	_; //insert modified code
	 }

	 modifier isVerifiedBuyer{
	 	//verify that the buyer is the predefined buyer
	 	require(
	 		msg.sender == buyer_transfer_add, "You are not Buyer."
	 	);
	 	_; //insert modified code	 	
	 }

	 modifier isVerifiedSeller{
	 	//verify that the buyer is the predefined seller
	 	require(
	 		msg.sender == seller_transfer_add, "You are not Seller."
	 	);
	 	_; //insert modified code
	 }

	 //util fundtion
	 function min(uint a, uint b) returns (uint){
	 	if (a>b) {
	 		return a;
	 	}
	 	else {
	 		return b;
	 	}
	 }
}