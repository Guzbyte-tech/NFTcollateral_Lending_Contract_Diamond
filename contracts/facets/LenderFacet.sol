// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LenderFacet {
    event LoanAccepted(
        uint256 indexed loanId,
        address indexed lender,
        uint256 amount
    );

    event LoanClosed(uint256 indexed loanId, address lender, LibDiamond.LoanStatus);

    //Place Loan Offer for a loan
    function acceptLoanOffer(uint256 _loanId) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibDiamond.Loan storage loan = ds.loanIdToLoan[_loanId];

        require(loan.borrower != address(0), "Loan does not exist");
        require(msg.sender != address(0), "Address zero not allowed");
        require(
            loan.status == LibDiamond.LoanStatus.Pending,
            "Loan is not pending"
        );

        //Get the currency to give the borrower and check if lender has sufficient of token
        IERC20 token = IERC20(loan.currency);
        require(
            token.balanceOf(msg.sender) > loan.amount,
            "Insufficient required token"
        );

        loan.lender = msg.sender;
        loan.status = LibDiamond.LoanStatus.Active;
        loan.dueDate = block.timestamp + loan.loanDuration;
        loan.acceptedAt = block.timestamp;

        ds.lendersToLoanId[msg.sender].push(_loanId);
        //Send Token to Borrower.
        require(
            token.transferFrom(msg.sender, loan.borrower, loan.amount),
            "Lending Transfer failed"
        );

        emit LoanAccepted(_loanId, msg.sender, loan.amount);
    }

    //If borrower didn't pay.
    function forceCloseLoan(uint256 _loanId) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibDiamond.Loan storage loan = ds.loanIdToLoan[_loanId];

        require(loan.borrower != address(0), "Loan does not exist");
        require(msg.sender != address(0), "Address zero not allowed");
        require(!loan.isRepaid, "Loan has been paid");
        require(loan.lender == msg.sender, "You're not the lender.");
        

        //Update Loan Status
        loan.status = LibDiamond.LoanStatus.Closed;

         // Check that the borrower owns the NFT collateral
        IERC721 collateralToken = IERC721(loan.collateral);
        require(
            collateralToken.ownerOf(loan.collateralTokenId) == msg.sender,
            "LoanFacet: Borrower does not own the NFT"
        );

        // Transfer NFT from borrower to contract for escrow
        collateralToken.safeTransferFrom(
            address(this),
            msg.sender,
            loan.collateralTokenId
        );

        emit LoanClosed(_loanId, msg.sender, LibDiamond.LoanStatus.Closed);  

    }
}
