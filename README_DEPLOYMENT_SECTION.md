# Deployment Section to Add to README

Add this section after the "Smart Contract" section in your README.md:

---

## 🚀 Development & Deployment

This project uses **Hardhat** as the primary development framework for compiling, testing, and deploying smart contracts.

### Prerequisites

- Node.js v18 or higher
- npm or yarn
- MetaMask or Web3 wallet
- Testnet ETH (Sepolia or Zama Devnet)

### Installation

```bash
# Install dependencies
npm install

# Copy environment configuration
cp .env.example .env

# Edit .env with your credentials
# PRIVATE_KEY=your_private_key_here
# SEPOLIA_RPC_URL=https://rpc.sepolia.org
# ETHERSCAN_API_KEY=your_etherscan_api_key
```

### Compilation

Compile smart contracts with Hardhat:

```bash
npm run compile
```

This generates:
- `artifacts/` - Contract ABIs and bytecode
- `cache/` - Hardhat cache files
- `typechain-types/` - TypeScript type definitions

### Testing

Run comprehensive test suite:

```bash
# Run all tests
npm run test

# Run tests with coverage report
npm run test:coverage
```

Test coverage includes:
- ✅ Contract deployment
- ✅ Lawyer registration and verification
- ✅ Consultation submission and assignment
- ✅ Admin functions
- ✅ Response provision
- ✅ Complete workflow simulation
- ✅ Edge cases

### Deployment

#### Deploy to Sepolia Testnet

```bash
npm run deploy:sepolia
```

Expected output:
```
🚀 Starting deployment process...
✅ Contract deployed successfully!

📍 Contract Address: 0xABCD...1234
Transaction Hash: 0x9876...5432
```

#### Deploy to Zama Devnet

```bash
npm run deploy:zama
```

#### Deploy to Local Hardhat Network

```bash
# Terminal 1: Start local node
npm run node

# Terminal 2: Deploy
npm run deploy:localhost
```

### Contract Verification

Verify deployed contract on Etherscan:

```bash
npm run verify:sepolia
```

This will:
1. Submit contract source code to Etherscan
2. Verify compilation matches deployed bytecode
3. Make contract code publicly readable

### Interaction Scripts

#### Interactive CLI

Launch interactive command-line interface:

```bash
npm run interact:sepolia
```

Available actions:
- 📝 Submit consultation (Client)
- ⚖️ Register as lawyer
- 📄 Get consultation details
- 👨‍⚖️ Get lawyer profile
- 📊 Get client statistics
- 🔧 Admin functions (assign, verify, rate)

#### Automated Simulation

Run complete workflow simulation:

```bash
npm run simulate:sepolia
```

Simulation performs:
1. Register 3 lawyers with different specialties
2. Verify all registered lawyers
3. Submit 5 legal consultations
4. Assign consultations to lawyers
5. Provide encrypted responses
6. Display statistics

---

## 📦 Deployment Information

### Network Configuration

| Network | Chain ID | RPC URL | Faucet |
|---------|----------|---------|--------|
| Sepolia Testnet | 11155111 | https://rpc.sepolia.org | [Get SepoliaETH](https://sepoliafaucet.com/) |
| Zama Devnet | 9000 | https://devnet.zama.ai | [Get Zama Tokens](https://faucet.zama.ai/) |
| Local Hardhat | 31337 | http://127.0.0.1:8545 | Pre-funded |

### Deployed Contract (Sepolia)

**Contract Information:**
- **Contract Name**: AnonymousLegalConsultation
- **Contract Address**: `0xBA9Daca2dEE126861963cd31752A9aCBc5488Df7`
- **Network**: Sepolia Testnet
- **Compiler**: Solidity 0.8.24
- **Optimization**: Enabled (200 runs)
- **License**: MIT

**Etherscan Links:**
- 📄 **Contract**: [View on Etherscan](https://sepolia.etherscan.io/address/0xBA9Daca2dEE126861963cd31752A9aCBc5488Df7)
- 📜 **Verified Code**: [View Source](https://sepolia.etherscan.io/address/0xBA9Daca2dEE126861963cd31752A9aCBc5488Df7#code)
- 📖 **Read Contract**: [Read Functions](https://sepolia.etherscan.io/address/0xBA9Daca2dEE126861963cd31752A9aCBc5488Df7#readContract)
- ✍️ **Write Contract**: [Write Functions](https://sepolia.etherscan.io/address/0xBA9Daca2dEE126861963cd31752A9aCBc5488Df7#writeContract)

**Deployment Details:**
```json
{
  "network": "sepolia",
  "contractAddress": "0xBA9Daca2dEE126861963cd31752A9aCBc5488Df7",
  "deployer": "0x...",
  "deploymentTime": "2025-01-XX",
  "transactionHash": "0x...",
  "blockNumber": XXXXXX,
  "gasUsed": XXXXXX,
  "verified": true
}
```

---

## 📝 Scripts Documentation

### Deployment Scripts

#### `scripts/deploy.js`
Comprehensive deployment script that:
- Validates deployer balance
- Deploys contract to specified network
- Saves deployment information to `deployments/`
- Displays contract address and transaction details
- Provides next steps for verification and interaction

Usage:
```bash
npx hardhat run scripts/deploy.js --network sepolia
```

#### `scripts/verify.js`
Contract verification script that:
- Loads deployment information
- Submits contract source to Etherscan
- Verifies compilation matches bytecode
- Updates deployment records with verification status

Usage:
```bash
npx hardhat run scripts/verify.js --network sepolia
```

#### `scripts/interact.js`
Interactive CLI for contract interaction:
- Submit consultations
- Register lawyers
- Query contract state
- Admin functions (assign, verify, rate)
- Real-time transaction feedback

Usage:
```bash
npx hardhat run scripts/interact.js --network sepolia
```

#### `scripts/simulate.js`
Complete workflow simulation:
- Registers multiple lawyers
- Submits various consultations
- Assigns and resolves consultations
- Displays comprehensive statistics

Usage:
```bash
npx hardhat run scripts/simulate.js --network sepolia
```

---

## 🧪 Testing Documentation

### Test Structure

```
test/
└── AnonymousLegalConsultation.test.js
    ├── Deployment Tests
    ├── Lawyer Registration Tests
    ├── Consultation Submission Tests
    ├── Admin Function Tests
    ├── Lawyer Response Tests
    ├── View Function Tests
    ├── Complete Workflow Tests
    └── Edge Case Tests
```

### Test Coverage

- **Deployment**: Contract initialization, admin setup, category configuration
- **Lawyer Registration**: Registration, verification, specialty validation
- **Consultations**: Submission, payment validation, client tracking
- **Admin Functions**: Assignment, verification, rating, deactivation
- **Responses**: Lawyer responses, consultation resolution
- **View Functions**: Data retrieval, statistics, error handling
- **Workflows**: Complete consultation lifecycle
- **Edge Cases**: Multiple operations, boundary conditions

Run tests:
```bash
npm run test
```

---

## 📚 Additional Resources

### Documentation Files

- **`DEPLOYMENT.md`** - Comprehensive deployment guide
- **`README.md`** - Project overview and features
- **`.env.example`** - Environment configuration template
- **`hardhat.config.js`** - Hardhat configuration

### External Resources

- [Hardhat Documentation](https://hardhat.org/docs)
- [Ethers.js Documentation](https://docs.ethers.org/)
- [Zama FHE Documentation](https://docs.zama.ai/)
- [Sepolia Testnet](https://sepolia.dev/)
- [Etherscan](https://etherscan.io/)

---

## 🔧 Configuration Files

### `hardhat.config.js`

Configures:
- Solidity compiler (v0.8.24)
- Network connections (Sepolia, Zama, Local)
- Etherscan verification
- Gas reporting
- Path configuration
- Optimization settings

### `package.json`

Includes npm scripts:
- `compile` - Compile contracts
- `test` - Run tests
- `deploy:sepolia` - Deploy to Sepolia
- `deploy:zama` - Deploy to Zama
- `verify:sepolia` - Verify on Etherscan
- `interact:*` - Interactive CLI
- `simulate:*` - Run simulation

### `.env.example`

Environment variables:
- `PRIVATE_KEY` - Deployment wallet private key
- `SEPOLIA_RPC_URL` - Sepolia RPC endpoint
- `ZAMA_RPC_URL` - Zama RPC endpoint
- `ETHERSCAN_API_KEY` - Etherscan API key
- `REPORT_GAS` - Gas reporting toggle

---

## 💡 Quick Start Guide

1. **Setup**:
   ```bash
   npm install
   cp .env.example .env
   # Edit .env with your credentials
   ```

2. **Compile**:
   ```bash
   npm run compile
   ```

3. **Test**:
   ```bash
   npm run test
   ```

4. **Deploy to Sepolia**:
   ```bash
   npm run deploy:sepolia
   ```

5. **Verify Contract**:
   ```bash
   npm run verify:sepolia
   ```

6. **Interact**:
   ```bash
   npm run interact:sepolia
   ```

7. **Run Simulation**:
   ```bash
   npm run simulate:sepolia
   ```

---

## 🛠️ Troubleshooting

### Common Issues

**Issue**: Deployment fails with "insufficient funds"
- **Solution**: Get testnet ETH from faucet

**Issue**: Verification fails
- **Solution**: Ensure ETHERSCAN_API_KEY is set in .env

**Issue**: Transaction timeout
- **Solution**: Increase timeout in hardhat.config.js

**Issue**: Contract not found
- **Solution**: Deploy contract first with `npm run deploy:sepolia`

For detailed troubleshooting, see [DEPLOYMENT.md](./DEPLOYMENT.md)

---
