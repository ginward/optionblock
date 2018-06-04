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
	 enum State { Inactive, Active, Mature }; 
	 State public state; 

	 uint strike; //the strike price, u
	 uint current; //current price 

	 mapping (string => uint) public balances; //the eth balances. 'Buyer' => Balance, 'Seller' => Balance
	 mapping (address => uint) public refund_balances; 

	 bool buyer_transfer;
	 address buyer_transfer_add;
	 uint buyer_transfer_price;

	 bool seller_transfer;
	 address seller_transfer_add; 
	 uint seller_transfer_price;

	 function CallOpt(address initbuyer, address initseller, uint initstrike) public {
	 	//the constructor sets the owner
	 	god=msg.sender;
	 	buyer=initbuyer;
	 	seller=initseller;
	 	strike=initstrike;
	 	state=State.Inactive; //set the state to be inactive in the beginning
	 }

	 function activeContract() sudo {
	 	//the function to activate the contract 
	 	//only owner can call this function 
	 	state=State.Active;
	 }

	 function MatureContract() sudo {
	 	//perform the action when contract matures

	 }

	 function DeActiveContract() sudo {
	 	//Deactive contract 
	 	state=State.Inactive
	 }

	 function initBuyerTransfer(target_price, target_add) sudo {
	 	//sudo user initiate the buyer transfer process 
	 	buyerTransfer=true;
	 	transfer_buyer=target_add;
	 	buyer_transfer_price=target_price;
	 }

	 function initSellerTransfer(target_price, target_add) sudo {
	 	//sudo user initiate teh seller transfer process
	 	sellerTransfer=true;
	 	seller_transfer_add=target_add;
	 	seller_transfer_price=target_price;
	 }

	 function buyerTransfer(address target) payable isVerifiedBuyer{
	 	infund=msg.value;
	    if(infund<buyer_transfer_price){
	 		//not enough fund, revert transaction
	 		revert();
	 	}
	 	refund=infund - buyer_transfer_price; 
	 	if (refund>=0){
	 		refund_balances[target]+=refund;
	 	}
	 	//send the fund from new buyer to old buyer
	 	buyer.transfer(buyer_transfer_price);
	 	buyer=target;
	 	buyer_transfer=false;
	 }

	 function sellerTransfer(address target) isVerifiedSeller payable{
	 	infund=msg.value;
	    if(infund<seller_transfer_pricer){
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

	 //the fallback function 
	 function() public payable{
	 	sender=msg.sender; //get the address of the sender of the message

	 }

	 modifier sudo{
	 	//function to check if the caller of a function is the owner
	 	require(
	 		msg.sender == god, "You are not God."
	 	);
	 	_; //insert modified code
	 }

	 modifier isVerifiedBuyer{
	 	//verify that the buyer is the predefined buyer, and there is sufficient funds 
	 	require(
	 		buyer_transfer == true, "Not for sale at the moment!"
	 	);
	 	require(
	 		msg.sender == buyer_transfer_add, "You are not Buyer."
	 	);
	 	_; //insert modified code	 	
	 }

	 modifier isVerifiedSeller{
	 	//verify that the buyer is the predefined seller, and there is sufficient funds 
	 	require(
	 		seller_transfer == true, "Not for sale at the moment!"
	 	);
	 	require(
	 		msg.sender == seller_transfer_add, "You are not Seller."
	 	);
	 	_; //insert modified code
	 }
}