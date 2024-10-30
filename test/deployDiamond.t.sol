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

        assertEq(mockERC20.balanceOf(deployer), 10000 * 10 ** 18);

        // Transfer some mock tokens to lender for testing
        mockERC20.transfer(lender, 10 * 10 ** 18);
        assertEq(mockERC20.balanceOf(lender), 10 * 10 ** 18);

        // Mint NFT to the borrower
        // uint256 tokenId = mockERC721.mintNFT(borrower);
        // assertEq(mockERC721.ownerOf(tokenId), borrower);

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();
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

        

        // Check loan details stored in the diamond storage
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 loanId = ds.loanCount; // Loan ID after creation
        console.log("Checking loan with ID:", loanId); // Should be 1 or greater now

        LibDiamond.Loan memory loan = ds.loanIdToLoan[loanId];
        console.log(loan.borrower);
        console.log(msg.sender);
        console.log(address(diamond));
        console.log(address(LoanContract));

        vm.stopPrank();

        // assertEq(loan.amount, 100 * 10 ** 18);
        // assertEq(loan.borrower, borrower);
        // assertEq(loan.status, LibDiamond.LoanStatus.Pending);
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}
