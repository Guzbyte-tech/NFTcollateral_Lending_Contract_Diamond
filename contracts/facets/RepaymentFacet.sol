// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RepaymentFacet {
    event LoanPaid(uint256 loanId, address paidBy, uint256 _amount);

    function repayLoan(uint256 _loanId) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibDiamond.Loan storage loan = ds.loanIdToLoan[_loanId];

        require(loan.borrower != address(0), "Loan does not exist");
        require(msg.sender != address(0), "Address zero not allowed");
        require(msg.sender == loan.borrower, "You are not the borrower.");
        require(!loan.isRepaid, "Loan Already Paid.");

        require(
            loan.status == LibDiamond.LoanStatus.Active,
            "Loan is not active"
        );

        IERC20 token = IERC20(loan.currency);
        // Calculate the interest rate
        uint256 amountToPay = calculateInterest(loan.amount, loan.interestRate);

        require(
            token.balanceOf(msg.sender) > amountToPay,
            "Insufficient required token"
        );

        loan.status = LibDiamond.LoanStatus.Closed;
        loan.isRepaid = true;
        loan.paidAt = block.timestamp;

        //Transfer token to lender.
        token.transferFrom(msg.sender, loan.lender, amountToPay);

        //Transfer NFT Collatary back to the borrower.
        // Check that the contract has the NFT collateral
        IERC721 collateralToken = IERC721(loan.collateral);
        require(
            collateralToken.ownerOf(loan.collateralTokenId) == address(this),
            "RepayFacet: Contract does not own the NFT"
        );

        // Transfer NFT from contract for escrow to borrower.
        collateralToken.safeTransferFrom(
            address(this),
            loan.borrower,
            loan.collateralTokenId
        );

        emit LoanPaid(_loanId, msg.sender, amountToPay);
    }

    function calculateInterest(
        uint256 principal,
        uint256 interestRate
    ) internal pure returns (uint256) {
        require(
            interestRate >= 0 && interestRate <= 100,
            "Interest rate must be between 0 and 100"
        );
        uint256 interestAmount = (principal * interestRate) / 100;

        return interestAmount;
    }
}
