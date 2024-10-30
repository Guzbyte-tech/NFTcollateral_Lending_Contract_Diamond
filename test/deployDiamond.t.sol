// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";

import "../contracts/Diamond.sol";

import {LoanFacet} from "../contracts/facets/LoanFacet.sol";
import {RepaymentFacet as RepaymentFacetContract} from "../contracts/facets/RepaymentFacet.sol";
import {LenderFacet as LenderFacetContract} from "../contracts/facets/LenderFacet.sol";

import "./helpers/DiamondUtils.sol";
import "forge-std/console.sol";

import {ERC20 as TOKEN} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC721 as ERC721TOKEN} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "../contracts/libraries/LibDiamond.sol";

contract MockERC20 is TOKEN {
    constructor() TOKEN("MockToken", "MTK") {
        _mint(msg.sender, 10000 * 10 ** decimals()); // Mint 10000 tokens to the deployer
    }
}

contract MockERC721 is ERC721TOKEN {
    uint256 public tokenCounter;

    constructor() ERC721TOKEN("MockNFT", "MNFT") {}

    function mintNFT(address to) public returns (uint256) {
        tokenCounter++;
        _mint(to, tokenCounter);
        return tokenCounter;
    }
}

contract DiamondDeployer is Test, DiamondUtils, IDiamondCut {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;

    LoanFacet LoanContract;
    RepaymentFacetContract paymentContract;
    LenderFacetContract lenderContract;

    MockERC20 mockERC20;
    MockERC721 mockERC721;
    address borrower;
    address lender;
    uint256 loanId;
    address deployer;

    function setUp() public {
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet));
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();

        LoanContract = new LoanFacet();
        paymentContract = new RepaymentFacetContract();
        lenderContract = new LenderFacetContract();

        borrower = address(0x1);
        lender = address(0x2);
        deployer = address(this);

        mockERC20 = new MockERC20();
        mockERC721 = new MockERC721();

        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](5);

        cut[0] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );

        cut[2] = (
            FacetCut({
                facetAddress: address(LoanContract),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("LoanFacet")
            })
        );

        cut[3] = (
            FacetCut({
                facetAddress: address(paymentContract),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("RepaymentFacet")
            })
        );

        cut[4] = (
            FacetCut({
                facetAddress: address(lenderContract),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("LenderFacet")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();

        assertEq(mockERC20.balanceOf(deployer), 10000 * 10 ** 18);

        // Transfer some mock tokens to lender for testing
        mockERC20.transfer(lender, 100 * 10 ** 18);
        assertEq(mockERC20.balanceOf(lender), 100 * 10 ** 18);

        // Mint NFT to the borrower
        // uint256 tokenId = mockERC721.mintNFT(borrower);
        // assertEq(mockERC721.ownerOf(tokenId), borrower);
    }

    function testCreateLoan() public {
        // setUp();
        // Lend some ERC721 tokens to the contract
        vm.startPrank(borrower);

        // Mint the NFT and approve it to the diamond contract
        uint256 tokenId = mockERC721.mintNFT(borrower);
        console.log("Minted Token ID:", tokenId);
        mockERC721.approve(address(diamond), tokenId);

        // Verify approval status
        assertEq(
            mockERC721.getApproved(tokenId),
            address(diamond),
            "Diamond contract should be approved"
        );

        // Call createLoanTerms through the diamond proxy
        LoanFacet(address(diamond)).createLoanTerms(
            address(mockERC20),
            30 days,
            10 * 10 ** 18,
            5,
            address(mockERC721),
            tokenId
        );

        console.log("Loan successfully created");

        uint256 loanId = LoanFacet(address(diamond)).getLoanCount();

        LibDiamond.Loan memory loan = LoanFacet(address(diamond)).getLoan(
            loanId
        );

        // Check loan details
        // console.log(loan);
        // console.log("Loan ID:", loanId);
        // console.log("Loan Borrower:", loan.borrower);

        vm.stopPrank();
        assertEq(loan.borrower, borrower);
        assertEq(loan.amount, 10 * 10 ** 18);
        assertEq(uint8(loan.status), uint8(LibDiamond.LoanStatus.Pending));
    }

    function testLenderAcceptLoan() public {
        vm.startPrank(borrower);
        // Mint the NFT and approve it to the diamond contract
        uint256 tokenId = mockERC721.mintNFT(borrower);
        console.log("Minted Token ID:", tokenId);
        mockERC721.approve(address(diamond), tokenId);
        assertEq(
            mockERC721.getApproved(tokenId),
            address(diamond),
            "Diamond contract should be approved"
        );

        LoanFacet(address(diamond)).createLoanTerms(
            address(mockERC20),
            30 days,
            10 * 10 ** 18,
            5,
            address(mockERC721),
            tokenId
        );

        console.log("Loan successfully created");

        uint256 loanId = LoanFacet(address(diamond)).getLoanCount();

        LibDiamond.Loan memory loan = LoanFacet(address(diamond)).getLoan(
            loanId
        );

        // Lender approves the ERC20 token for the diamond contract
        vm.startPrank(lender);
        mockERC20.approve(address(diamond), 100 * 10 ** 18);

        // Lender accepts the loan
        LenderFacetContract(address(diamond)).acceptLoanOffer(loanId);

        // Check loan status and lender
        LibDiamond.Loan memory loan2 = LoanFacet(address(diamond)).getLoan(
            loanId
        );
        assertEq(uint8(loan2.status), uint8(LibDiamond.LoanStatus.Active));
        assertEq(loan2.lender, lender);
    }

    function testRepayLoan() public {
        vm.startPrank(borrower);
        uint256 tokenId = mockERC721.mintNFT(borrower);
        console.log("Minted Token ID:", tokenId);
        mockERC721.approve(address(diamond), tokenId);
        assertEq(
            mockERC721.getApproved(tokenId),
            address(diamond),
            "Diamond contract should be approved"
        );

        LoanFacet(address(diamond)).createLoanTerms(
            address(mockERC20),
            30 days,
            10 * 10 ** 18,
            5,
            address(mockERC721),
            tokenId
        );

        uint256 loanId = LoanFacet(address(diamond)).getLoanCount();

        LibDiamond.Loan memory loan = LoanFacet(address(diamond)).getLoan(
            loanId
        );
        vm.stopPrank();

        // Lender approves the ERC20 token for the diamond contract
        vm.startPrank(lender);

        mockERC20.approve(address(diamond), 100 * 10 ** 18);

        // Lender accepts the loan
        LenderFacetContract(address(diamond)).acceptLoanOffer(loanId);

        uint256 lenderBalBefore = MockERC20(loan.currency).balanceOf(lender);

        // Check loan status and lender
        LibDiamond.Loan memory loan2 = LoanFacet(address(diamond)).getLoan(
            loanId
        );
        vm.stopPrank();

        // // Move forward in time to simulate loan expiration
        vm.warp(block.timestamp + 30 days);

        //Borrower RepayLoan
        vm.startPrank(borrower);
        mockERC20.approve(address(diamond), 100 * 10 ** 18);
        RepaymentFacetContract(address(diamond)).repayLoan(loanId);

        // Check loan status and collateral transfer
        LibDiamond.Loan memory loan3 = LoanFacet(address(diamond)).getLoan(
            loanId
        );

        uint256 lenderBalAfter = MockERC20(loan.currency).balanceOf(lender);
        vm.stopPrank();

        // console.log(lenderBalBefore);
        // console.log(lenderBalAfter);

        assertGt(lenderBalAfter, lenderBalBefore);
        assertEq(uint8(loan3.status), uint8(LibDiamond.LoanStatus.Closed));
        assertEq(mockERC721.ownerOf(tokenId), borrower);
        assertEq(loan3.isRepaid, true);
        assertEq(loan3.paidAt, block.timestamp);
        vm.stopPrank();
    }

    function testForceCloseLoan() public {
        vm.startPrank(borrower);
        uint256 tokenId = mockERC721.mintNFT(borrower);
        console.log("Minted Token ID:", tokenId);
        mockERC721.approve(address(diamond), tokenId);
        assertEq(
            mockERC721.getApproved(tokenId),
            address(diamond),
            "Diamond contract should be approved"
        );

        LoanFacet(address(diamond)).createLoanTerms(
            address(mockERC20),
            30 days,
            10 * 10 ** 18,
            5,
            address(mockERC721),
            tokenId
        );

        uint256 loanId = LoanFacet(address(diamond)).getLoanCount();

        LibDiamond.Loan memory loan = LoanFacet(address(diamond)).getLoan(
            loanId
        );
        vm.stopPrank();

        // Lender approves the ERC20 token for the diamond contract
        vm.startPrank(lender);
        mockERC20.approve(address(diamond), 100 * 10 ** 18);

        // Lender accepts the loan
        LenderFacetContract(address(diamond)).acceptLoanOffer(loanId);

        // Check loan status and lender
        LibDiamond.Loan memory loan2 = LoanFacet(address(diamond)).getLoan(
            loanId
        );

        // // Move forward in time to simulate loan expiration
        vm.warp(block.timestamp + 30 days);

        // // Lender force closes the loan
        LenderFacetContract(address(diamond)).forceCloseLoan(loanId);

        // Check loan status and collateral transfer
        LibDiamond.Loan memory loan3 = LoanFacet(address(diamond)).getLoan(
            loanId
        );
        assertEq(uint8(loan3.status), uint8(LibDiamond.LoanStatus.Closed));
        assertEq(mockERC721.ownerOf(tokenId), lender);
        vm.stopPrank();

        // assertEq(uint8(loan2.status), uint8(LibDiamond.LoanStatus.Active));
        // assertEq(loan2.lender, lender);
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}
