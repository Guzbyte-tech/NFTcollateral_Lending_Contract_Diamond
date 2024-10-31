// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract LoanFacet {
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

    event LoanCancelled(uint256 _loanid, LibDiamond.LoanStatus _status);

    //Borrower ask for loan by specifying loan terms
    function createLoanTerms(
        address _currency,
        uint256 _duration,
        // uint256 _dueDate,
        uint256 _amount,
        uint256 _interestRate,
        address _collateral,
        uint256 _collateralTokenId
    ) external {
        require(_currency != address(0), "Currency address cannot be zero");
        require(_duration > 0, "Invalid duration");
        require(_amount > 0, "Invalid amount");
        require(
            _interestRate >= 0 && _interestRate <= 100,
            "Invalid interest rate"
        );
        require(_collateral != address(0), "Collateral address cannot be zero");
        require(_collateralTokenId > 0, "Invalid collateral token Id");

        // Check that the borrower owns the NFT collateral
        IERC721 collateralToken = IERC721(_collateral);
        require(
            collateralToken.ownerOf(_collateralTokenId) == msg.sender,
            "LoanFacet: Borrower does not own the NFT"
        );

        // Transfer NFT from borrower to contract for escrow
        collateralToken.safeTransferFrom(
            msg.sender,
            address(this),
            _collateralTokenId
        );

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        ds.loanCount++;
        uint256 currentLoanId = ds.loanCount;

        ds.loanIdToLoan[currentLoanId] = LibDiamond.Loan({
            loanId: currentLoanId,
            borrower: msg.sender,
            currency: _currency,
            loanDuration: _duration,
            dueDate: block.timestamp + _duration,
            isRepaid: false,
            amount: _amount,
            interestRate: _interestRate, //In percent
            collateral: _collateral,
            collateralTokenId: _collateralTokenId,
            status: LibDiamond.LoanStatus.Pending,
            lender: address(0),
            acceptedAt: 0,
            paidAt: 0
        });

        ds.BorrowerToLoanId[msg.sender].push(currentLoanId);

        emit LoanCreated(
            currentLoanId,
            msg.sender,
            _currency,
            _duration,
            block.timestamp + _duration,
            _amount,
            _interestRate,
            _collateral,
            _collateralTokenId
        );
    }

    function withdrawLoanOffer(uint256 _loanId) external onlyBorrower(_loanId) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibDiamond.Loan storage loan = ds.loanIdToLoan[_loanId];
        require(loan.borrower != address(0), "Loan does not exist");
        require(
            loan.status == LibDiamond.LoanStatus.Pending,
            "Loan already in-progress.."
        );
        require(loan.dueDate > block.timestamp, "Loan has expired");

        loan.status = LibDiamond.LoanStatus.Cancelled;

        // Check that the contract has the NFT collateral
        IERC721 collateralToken = IERC721(loan.collateral);
        require(
            collateralToken.ownerOf(loan.collateralTokenId) == address(this),
            "Contract does not own the NFT"
        );
        // Transfer NFT from borrower to contract for escrow
        collateralToken.safeTransferFrom(
            address(this),
            loan.borrower,
            loan.collateralTokenId
        );

        emit LoanCancelled(_loanId, LibDiamond.LoanStatus.Cancelled);
    }

    modifier onlyBorrower(uint256 _loanId) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibDiamond.Loan storage loan = ds.loanIdToLoan[_loanId];
        require(loan.borrower == msg.sender, "Not owner of this loan");
        _;
    }

    //Get Loan
    function getLoan(
        uint256 _loanId
    ) external view returns (LibDiamond.Loan memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibDiamond.Loan storage loan = ds.loanIdToLoan[_loanId];
        require(loan.borrower != address(0), "Loan does not exist");
        return loan;
    }

    function getLoanCount() external view returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.loanCount;
    }
}
