# Simple Voting System on Aptos

## Project Title
Aptos SimpleVoting - A Decentralized Voting Smart Contract

## Project Description
SimpleVoting is a lightweight, secure, and transparent voting system built on the Aptos blockchain. This smart contract allows users to create custom polls with multiple options and enables other participants to cast their votes in a decentralized manner. The system is designed with simplicity and security in mind, preventing duplicate votes and maintaining immutable records of all voting activities.

The contract includes essential functionality:
- Poll creation with customizable options
- Secure voting mechanism
- Protection against duplicate voting
- Active/inactive status management

## Project Vision
The vision behind SimpleVoting is to democratize decision-making processes by leveraging blockchain technology. By providing a transparent, tamper-proof voting system, we aim to enable communities, organizations, and DAOs to conduct trustless voting without relying on centralized authorities. Our goal is to make blockchain-based voting accessible to everyone, regardless of their technical expertise.

SimpleVoting represents the first step toward a comprehensive suite of governance tools that can empower decentralized communities to make collective decisions efficiently and securely.

## Future Scope
The current implementation provides basic voting functionality, but there are numerous enhancements planned for future versions:

1. **Time-bound Polls**: Add functionality to set start and end times for voting periods
2. **Weighted Voting**: Allow votes to carry different weights based on token holdings or other criteria
3. **Delegate Voting**: Enable users to delegate their voting power to trusted representatives
4. **Private Voting**: Implement zero-knowledge proofs for anonymous voting while maintaining verifiability
5. **Multi-signature Poll Creation**: Require approval from multiple parties to create official polls
6. **Result Verification**: Add functions to verify and publish voting results automatically
7. **Integration with Aptos Tokenization**: Connect voting power to token ownership
8. **UI/UX Frontend**: Develop a user-friendly interface for interacting with the contract

## Contract Details
- **Module Address**: `0x8e46115deae69c3ffc41c50f29c94501935467de0212a666d2f0f0b83f1574ac`
- **Transaction Hash**: `0xd91920a2697ba0fbc8039625b57b1050edafd3bcfbbd6b3821d6460facabaced`
- **Module Name**: `MyModule::SimpleVoting`

### Key Functions:
- `create_poll`: Creates a new voting poll with specified options
- `vote`: Allows users to cast a vote for their preferred option

### Error Codes:
- `E_ALREADY_VOTED (1)`: User has already cast a vote in this poll
- `E_VOTING_CLOSED (2)`: The poll is no longer active and doesn't accept new votes

---

To interact with this contract, you'll need an Aptos wallet and some APT tokens for transaction fees. You can call the contract functions through the Aptos CLI or by building a frontend application that interfaces with the Aptos blockchain.
