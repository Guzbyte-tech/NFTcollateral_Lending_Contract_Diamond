// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";

contract BorrowerFaucet {
    event LoanCreated(
        uint256 indexed loanId,
        address indexed _borrower,
        address _currency,
        uint256 _duration,
        uint256 _dueDate,
        uint256 _amount,
        uint256 _interestRate,
        address _collateral,
        uint256 _collateralTokenId
    );

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
        require(_currency != address(0), "Currency address cannot be zero");
        require(_duration > 0, "Invalid duration");
        require(_dueDate > block.timestamp, "Invalid due date");
        require(_dueDate == block.timestamp + _duration, "Invalid due date");
        require(_amount > 0, "Invalid amount");
        require(
            _interestRate >= 0 && _interestRate <= 100,
            "Invalid interest rate"
        );
        require(_collateral != address(0), "Collateral address cannot be zero");
        require(_collateralTokenId > 0, "Invalid collateral token Id");

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 _loanCount = ds.loanCount + 1;

        ds.loanIdToLoan[_loanCount] = LibDiamond.Loan({
            loanId: _loanCount,
            borrower: msg.sender,
            currency: _currency,
            loanDuration: _duration,
            dueDate: _dueDate,
            isRepaid: false,
            amount: _amount,
            interestRate: _interestRate,
            collateral: _collateral,
            collateralTokenId: _collateralTokenId
        });

        ds.BorrowerToLoanId[msg.sender].push(_loanCount);
        ds.loanCount++;

        emit LoanCreated(_loanCount, msg.sender, _currency, _duration, _dueDate, _amount, _interestRate, _collateral, _collateralTokenId);

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
