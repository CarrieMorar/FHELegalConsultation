# Deployment Guide

This document provides comprehensive instructions for deploying and interacting with the AnonymousLegalConsultation smart contract.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Compilation](#compilation)
- [Testing](#testing)
- [Deployment](#deployment)
- [Verification](#verification)
- [Interaction](#interaction)
- [Simulation](#simulation)
- [Network Information](#network-information)
- [Deployed Contracts](#deployed-contracts)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before deploying the contract, ensure you have the following installed:

- **Node.js** (v18 or higher)
- **npm** or **yarn**
- **MetaMask** or another Web3 wallet
- **Git** (optional)

---

## Installation

1. **Clone the repository** (if applicable):
   ```bash
   git clone <repository-url>
   cd anonymous-legal-consultation
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

   This will install:
   - Hardhat development framework
   - Ethers.js for blockchain interaction
   - Testing libraries (Chai, Mocha)
   - Verification plugins

---

## Configuration

1. **Create environment file**:
   ```bash
   cp .env.example .env
   ```

2. **Configure `.env` file**:
   ```env
   # Private key (without 0x prefix)
   PRIVATE_KEY=your_private_key_here

   # RPC URLs
   SEPOLIA_RPC_URL=https://rpc.sepolia.org
   ZAMA_RPC_URL=https://devnet.zama.ai

   # API Keys
   ETHERSCAN_API_KEY=your_etherscan_api_key_here

   # Optional
   REPORT_GAS=false
   COINMARKETCAP_API_KEY=your_coinmarketcap_api_key_here
   ```

3. **Get testnet ETH**:
   - **Sepolia**: https://sepoliafaucet.com/
   - **Zama Devnet**: https://faucet.zama.ai/

⚠️ **Security Warning**: Never commit your `.env` file or expose your private key!

---

## Compilation

Compile the smart contracts:

```bash
npm run compile
```

Expected output:
```
Compiled 1 Solidity file successfully
```

The compilation generates:
- `artifacts/` - Compiled contract artifacts
- `cache/` - Hardhat cache files
- `typechain-types/` - TypeScript type definitions

---

## Testing

Run the comprehensive test suite:

```bash
npm run test
```

Run tests with coverage:

```bash
npm run test:coverage
```

Expected test results:
```
AnonymousLegalConsultation
  ✓ Deployment
  ✓ Lawyer Registration
  ✓ Consultation Submission
  ✓ Admin Functions
  ✓ Lawyer Response
  ✓ View Functions
  ✓ Complete Workflow
  ✓ Edge Cases

All tests passed!
```

---

## Deployment

### Local Deployment (Hardhat Network)

1. **Start local node**:
   ```bash
   npm run node
   ```

2. **Deploy to local network** (in new terminal):
   ```bash
   npm run deploy:localhost
   ```

### Sepolia Testnet Deployment

```bash
npm run deploy:sepolia
```

Expected output:
```
🚀 Starting deployment process...

📋 Deployment Configuration:
──────────────────────────────────────────────────
Network:          sepolia
Deployer:         0x1234...5678
Balance:          1.5 ETH
──────────────────────────────────────────────────

⏳ Deploying AnonymousLegalConsultation contract...
✅ Contract deployed successfully!

📍 Deployment Information:
──────────────────────────────────────────────────
Contract Address: 0xABCD...1234
Deployment Time:  12.5s
Transaction Hash: 0x9876...5432
Block Number:     4567890
──────────────────────────────────────────────────
```

### Zama Devnet Deployment

```bash
npm run deploy:zama
```

---

## Verification

Verify the deployed contract on Etherscan (Sepolia only):

```bash
npm run verify:sepolia
```

Expected output:
```
🔍 Starting contract verification...

⏳ Submitting contract for verification...
✅ Contract verified successfully!

🔗 View Verified Contract:
   https://sepolia.etherscan.io/address/0xABCD...1234#code
```

---

## Interaction

### Interactive CLI

Launch the interactive command-line interface:

```bash
npm run interact:sepolia
```

Available actions:
1. Submit Consultation (Client)
2. Register as Lawyer
3. Get Consultation Details
4. Get Lawyer Profile
5. Get Client Statistics
6. View Legal Categories
7. Check Lawyer Registration Status
8. Get System Statistics
9. Admin: Assign Consultation to Lawyer
10. Admin: Verify Lawyer
11. Admin: Update Lawyer Rating
12. Admin: Deactivate Lawyer
13. Admin: Withdraw Fees

### Programmatic Interaction

You can also interact with the contract using custom scripts:

```javascript
const hre = require("hardhat");

async function main() {
  const contractAddress = "0xYourContractAddress";
  const contract = await hre.ethers.getContractAt(
    "AnonymousLegalConsultation",
    contractAddress
  );

  // Submit consultation
  const tx = await contract.submitConsultation(
    10001,
    1,
    "What are my rights?",
    { value: hre.ethers.parseEther("0.001") }
  );

  await tx.wait();
  console.log("Consultation submitted!");
}

main();
```

---

## Simulation

Run a complete simulation of the platform workflow:

```bash
npm run simulate:sepolia
```

The simulation performs:
1. **Lawyer Registration** - Registers 3 lawyers with different specialties
2. **Lawyer Verification** - Admin verifies all registered lawyers
3. **Consultation Submission** - Clients submit 5 legal consultations
4. **Consultation Assignment** - Admin assigns consultations to lawyers
5. **Lawyer Responses** - Lawyers provide encrypted responses
6. **Statistics Display** - Shows platform statistics and results

Expected output:
```
═══════════════════════════════════════════════════════════════════
  🎭 LEGAL CONSULTATION PLATFORM SIMULATION
═══════════════════════════════════════════════════════════════════

⚖️  PHASE 1: LAWYER REGISTRATION
✅ 3 lawyers registered

✅ PHASE 2: LAWYER VERIFICATION
✅ All lawyers verified

📝 PHASE 3: CLIENT CONSULTATIONS
✅ 5 consultations submitted

🔗 PHASE 4: CONSULTATION ASSIGNMENT
✅ All consultations assigned

💬 PHASE 5: LAWYER RESPONSES
✅ All responses provided

📊 FINAL STATISTICS
Total Consultations:  5
Total Lawyers:        3
Verified Lawyers:     3
Contract Balance:     0.015 ETH
```

---

## Network Information

### Sepolia Testnet

- **Chain ID**: 11155111
- **RPC URL**: https://rpc.sepolia.org
- **Explorer**: https://sepolia.etherscan.io/
- **Currency**: SepoliaETH (test ETH)
- **Faucet**: https://sepoliafaucet.com/

### Zama Devnet

- **Chain ID**: 9000
- **RPC URL**: https://devnet.zama.ai
- **Explorer**: Coming soon
- **Currency**: Zama test tokens
- **Faucet**: https://faucet.zama.ai/

### Local Hardhat Network

- **Chain ID**: 31337
- **RPC URL**: http://127.0.0.1:8545
- **Pre-funded Accounts**: 20 accounts with 10,000 ETH each

---

## Deployed Contracts

### Sepolia Testnet Deployment

**Contract Information:**
- **Contract Name**: AnonymousLegalConsultation
- **Contract Address**: `0xBA9Daca2dEE126861963cd31752A9aCBc5488Df7` (Example)
- **Network**: Sepolia Testnet (Chain ID: 11155111)
- **Compiler Version**: 0.8.24
- **Optimization**: Enabled (200 runs)
- **License**: MIT

**Etherscan Links:**
- **Contract Address**: https://sepolia.etherscan.io/address/0xBA9Daca2dEE126861963cd31752A9aCBc5488Df7
- **Verified Code**: https://sepolia.etherscan.io/address/0xBA9Daca2dEE126861963cd31752A9aCBc5488Df7#code
- **Read Contract**: https://sepolia.etherscan.io/address/0xBA9Daca2dEE126861963cd31752A9aCBc5488Df7#readContract
- **Write Contract**: https://sepolia.etherscan.io/address/0xBA9Daca2dEE126861963cd31752A9aCBc5488Df7#writeContract

**Deployment Details:**
- **Deployer**: [Deployer Address]
- **Deployment Date**: [Deployment Date]
- **Transaction Hash**: [Transaction Hash]
- **Block Number**: [Block Number]
- **Gas Used**: [Gas Amount]
- **Gas Price**: [Gas Price in Gwei]

**Constructor Arguments:**
- None (no constructor parameters)

**Initial State:**
- Admin: [Deployer Address]
- Total Consultations: 0
- Total Lawyers: 0
- Verified Lawyers: 0

### Zama Devnet Deployment

**Contract Information:**
- **Contract Name**: AnonymousLegalConsultation
- **Contract Address**: `0x...` (To be deployed)
- **Network**: Zama Devnet (Chain ID: 9000)

---

## Contract Functions

### Client Functions

#### `submitConsultation(uint32 clientId, uint32 categoryId, string question)`
Submit an encrypted legal consultation.

**Parameters:**
- `clientId`: Anonymous client identifier
- `categoryId`: Legal category (1-8)
- `question`: Encrypted question text

**Payment**: Requires minimum 0.001 ETH

**Example:**
```javascript
await contract.submitConsultation(
  10001,
  1,
  "What are my contract rights?",
  { value: ethers.parseEther("0.001") }
);
```

### Lawyer Functions

#### `registerLawyer(uint32 specialty)`
Register as a lawyer with a legal specialty.

**Parameters:**
- `specialty`: Legal specialty (1-8)

**Example:**
```javascript
await contract.registerLawyer(1); // Civil Law
```

#### `provideResponse(uint256 consultationId, string response)`
Provide an encrypted response to an assigned consultation.

**Parameters:**
- `consultationId`: ID of the consultation
- `response`: Encrypted response text

**Example:**
```javascript
await contract.provideResponse(1, "Here is my legal advice...");
```

### Admin Functions

#### `verifyLawyer(uint256 lawyerId)`
Verify a registered lawyer.

#### `assignConsultation(uint256 consultationId, uint256 lawyerId)`
Assign a consultation to a verified lawyer.

#### `updateLawyerRating(uint256 lawyerId, uint32 newRating)`
Update a lawyer's rating (0-100).

#### `deactivateLawyer(uint256 lawyerId)`
Deactivate a lawyer's account.

#### `withdrawFees(uint256 amount)`
Withdraw accumulated platform fees.

### View Functions

#### `getConsultationDetails(uint256 consultationId)`
Get details of a specific consultation.

#### `getLawyerProfile(uint256 lawyerId)`
Get profile information of a lawyer.

#### `getClientStats(address clientAddress)`
Get statistics for a specific client.

#### `getSystemStats()`
Get overall platform statistics.

---

## Troubleshooting

### Common Issues

#### 1. Deployment Failed - Insufficient Funds

**Error:**
```
Error: insufficient funds for intrinsic transaction cost
```

**Solution:**
- Check your account balance: Ensure you have enough testnet ETH
- Get more testnet ETH from faucets
- Verify your PRIVATE_KEY in .env file

#### 2. Verification Failed

**Error:**
```
Error: Etherscan API key not configured
```

**Solution:**
- Add your Etherscan API key to `.env`:
  ```
  ETHERSCAN_API_KEY=your_api_key_here
  ```
- Get API key from: https://etherscan.io/myapikey

#### 3. Network Connection Issues

**Error:**
```
Error: could not detect network
```

**Solution:**
- Check your RPC URL in `.env`
- Try alternative RPC providers:
  - Sepolia: https://rpc2.sepolia.org
  - Infura: https://sepolia.infura.io/v3/YOUR_PROJECT_ID

#### 4. Transaction Timeout

**Error:**
```
Error: timeout exceeded
```

**Solution:**
- Increase timeout in `hardhat.config.js`:
  ```javascript
  mocha: {
    timeout: 300000 // 5 minutes
  }
  ```

#### 5. Contract Not Deployed

**Error:**
```
Deployment file not found
```

**Solution:**
- Deploy the contract first:
  ```bash
  npm run deploy:sepolia
  ```

---

## Gas Optimization

### Estimated Gas Costs (Sepolia)

| Function | Gas Cost | USD Cost (at $2000 ETH, 30 gwei) |
|----------|----------|-----------------------------------|
| Deploy Contract | ~2,500,000 | ~$0.15 |
| Register Lawyer | ~150,000 | ~$0.009 |
| Submit Consultation | ~200,000 | ~$0.012 |
| Provide Response | ~100,000 | ~$0.006 |
| Assign Consultation | ~80,000 | ~$0.005 |

### Gas Saving Tips

1. **Batch Operations**: Group multiple operations when possible
2. **Optimize Storage**: Minimize storage writes
3. **Use Events**: Prefer events over storage for historical data
4. **Proper Data Types**: Use uint32 instead of uint256 where applicable

---

## Best Practices

1. **Security**
   - Never share your private key
   - Always use `.env` for sensitive data
   - Verify contract code before deployment

2. **Testing**
   - Run full test suite before deployment
   - Test on local network first
   - Deploy to testnet before mainnet

3. **Verification**
   - Verify contracts immediately after deployment
   - Keep deployment records
   - Document all contract addresses

4. **Monitoring**
   - Monitor contract events
   - Track gas costs
   - Keep deployment logs

---

## Additional Resources

- **Hardhat Documentation**: https://hardhat.org/docs
- **Ethers.js Documentation**: https://docs.ethers.org/
- **Zama FHE Documentation**: https://docs.zama.ai/
- **Sepolia Testnet**: https://sepolia.dev/
- **Etherscan**: https://etherscan.io/

---

## Support

For issues or questions:
- Open an issue on GitHub
- Check existing documentation
- Review test files for usage examples

---

**Last Updated**: January 2025
**Version**: 1.0.0
