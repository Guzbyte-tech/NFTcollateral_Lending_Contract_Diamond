// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";

contract BorrowerFaucet {
    //Borrower ask for loan by specifying loan terms
    function createLoanTerms(
        address _currency,
        uint256 _duration,
        uint256 _dueDate,
        uint256 _amount,
        uint256 _interestRate,
        address _collateral,
        uint256 _collateralTokenId
    ) external {
        require(msg.sender != address(0), "Address zero not allowed");
        require(_currency != address(0), "Address zero not allowed");
        require(_currency != address(0), "Address zero not allowed");

    }

    //Borrower accepts loan offer here based on lon
    //Once loan is accepted the NFT is transfered to the contract as an excrow
    //Crypto is sent from lender to the borrower.
    //Loan duration starts based on loan terms
    function acceptLoanOffer() external {}

    //Borrower must return amount plus interest
    //Once complete the NFT is returned back
    function repay() external {}
}
