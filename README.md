# NFT-Collateralized Lending Platform - Diamond Contract Architecture

This project is a decentralized lending platform that allows users to collateralize NFTs in exchange for cryptocurrency loans. Built using the **Diamond Standard (EIP-2535)**, this contract system offers modular, upgradable, and gas-efficient smart contracts, enabling easy addition and modification of features.

## Features

- **NFT Collateralization**: Borrowers can lock up NFTs as collateral for loans.
- **Diamond Contract Structure**: Using facets to modularize functionality, including `LoanFacet`, `LenderFacet`, and `RepaymentFacet`.
- **Flexible Loan Terms**: Customizable loan amounts, durations, and interest rates.
- **Escrow Management**: The platform acts as an escrow, transferring collateralized NFTs to lenders if loans are not repaid.
- **Time Simulation (for Testing)**: Loan expiry and repayment scenarios can be tested with time manipulation.

## Project Structure

### Contracts

- **Diamond.sol**: Implements the core Diamond Proxy logic, delegating calls to facets based on function selectors.
- **LoanFacet.sol**: Contains functionality for creating loan terms, transferring NFT collateral, and loan state management.
- **LenderFacet.sol**: Handles lender interactions, such as accepting loans and force-closing on defaults.
- **RepaymentFacet.sol**: Manages repayments, interest calculation, and updating loan status.
- **LibDiamond.sol**: Manages shared state variables (loan data, mappings) and stores diamond-related data.

### Testing

Tests are written using **Foundry** to simulate different lending scenarios. Tests include:

- Loan creation and validation.
- Time-based tests for loan expiration.
- Forced loan closures and collateral transfers.

### Deployment & Testing Tools

- **Foundry**: For testing, debugging, and simulating blockchain environments.
- **OpenZeppelin Contracts**: For ERC20 and ERC721 token standards.
- **Solidity Console**: Used in debugging to log state changes.

## Installation

1. **Clone the repository:**
   ```bash
   git clone git@github.com:Guzbyte-tech/NFTcollateral_Lending_Contract_Diamond.git
   cd NFTcollateral_Lending_Contract_Diamond
   ```

2. **Install Foundry:**
   [Follow the Foundry installation guide here](https://book.getfoundry.sh/getting-started/installation.html).

3. **Install dependencies:**
   ```bash
   forge install
   ```

4. **Compile the contracts:**
   ```bash
   forge build
   ```

## Running Tests

Tests are located in the `test` directory and use the Foundry testing framework. Run all tests using:

```bash
forge test
```

To simulate time in tests, Foundry’s `vm.warp` is used to control `block.timestamp`.

## Example Usage

1. **Create a Loan**:
   - Borrowers call `createLoanTerms` on the `LoanFacet`, specifying currency, amount, interest, and collateral NFT details.
   
2. **Lender Acceptance**:
   - Lenders can accept a loan, initiating the loan duration and transferring tokens to the borrower.

3. **Repayment**:
   - Borrowers repay the loan within the duration specified, paying principal plus interest.

4. **Force Closure**:
   - If the borrower fails to repay, the lender can call `forceCloseLoan` to transfer the NFT collateral to their address.

## Contributing

1. Fork the project
2. Create a feature branch: `git checkout -b feature-name`
3. Commit your changes: `git commit -m 'Add some feature'`
4. Push to the branch: `git push origin feature-name`
5. Open a pull request

## License

This project is licensed under the MIT License.