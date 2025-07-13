# CI/CD Pipeline Documentation

## Overview

This document describes the Continuous Integration and Continuous Deployment (CI/CD) pipeline for the Anonymous Legal Consultation Platform. The pipeline is implemented using GitHub Actions and runs automated tests, code quality checks, and security scans on every push and pull request.

---

## Table of Contents

- [Pipeline Architecture](#pipeline-architecture)
- [Workflows](#workflows)
- [Code Quality Tools](#code-quality-tools)
- [Configuration Files](#configuration-files)
- [Setup Instructions](#setup-instructions)
- [Local Testing](#local-testing)
- [Troubleshooting](#troubleshooting)

---

## Pipeline Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   GitHub Event Trigger                   │
│         (push to main/develop, pull request)            │
└──────────────────┬──────────────────────────────────────┘
                   │
    ┌──────────────┼──────────────┬──────────────┐
    │              │              │              │
    ▼              ▼              ▼              ▼
┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐
│  Lint  │    │  Test  │    │ Build  │    │Security│
│        │    │        │    │        │    │        │
│ - ESL  │    │Node 18 │    │Compile │    │  Audit │
│ - Soli │    │Node 20 │    │Artif's │    │CodeQL  │
│ - Prett│    │Coverage│    │        │    │DepRev  │
└────┬───┘    └────┬───┘    └────┬───┘    └────┬───┘
     │             │             │             │
     └─────────────┴─────────────┴─────────────┘
                   │
                   ▼
          ┌──────────────┐
          │   Success    │
          │  All Passed  │
          └──────────────┘
```

---

## Workflows

### 1. Test Suite Workflow (`.github/workflows/test.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

**Jobs:**

#### Job 1: Code Quality Checks (`lint`)
- **Runner**: Ubuntu Latest
- **Node Version**: 20.x
- **Steps**:
  1. Checkout code
  2. Setup Node.js
  3. Install dependencies (`npm ci`)
  4. Run Prettier formatting check
  5. Run Solhint (Solidity linter)
  6. Run ESLint (JavaScript linter)

**Scripts executed:**
```bash
npm run prettier:check
npm run lint:solidity
npm run lint
```

#### Job 2: Test Suite (`test`)
- **Runner**: Ubuntu Latest
- **Node Versions**: 18.x, 20.x (matrix)
- **Steps**:
  1. Checkout code
  2. Setup Node.js (matrix version)
  3. Install dependencies
  4. Compile contracts
  5. Run tests
  6. Generate coverage report (Node 20.x only)
  7. Upload to Codecov

**Scripts executed:**
```bash
npm ci
npm run compile
npm test
npm run test:coverage  # Node 20.x only
```

**Coverage Upload:**
- Uploads `coverage/lcov.info` to Codecov
- Only runs on Node 20.x
- Requires `CODECOV_TOKEN` secret

#### Job 3: Build Check (`build`)
- **Runner**: Ubuntu Latest
- **Node Version**: 20.x
- **Steps**:
  1. Checkout code
  2. Setup Node.js
  3. Install dependencies
  4. Compile contracts
  5. Verify artifacts generated

**Verification:**
```bash
npm run compile
ls -la artifacts/
```

#### Job 4: Gas Report (`gas-report`)
- **Runner**: Ubuntu Latest
- **Node Version**: 20.x
- **Trigger**: Pull requests only
- **Steps**:
  1. Checkout code
  2. Setup Node.js
  3. Install dependencies
  4. Compile contracts
  5. Generate gas report
  6. Comment report on PR

**Environment:**
```bash
REPORT_GAS=true npm test
```

---

### 2. Security Workflow (`.github/workflows/security.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches
- Weekly schedule (Mondays at 9:00 AM UTC)

**Jobs:**

#### Job 1: NPM Audit (`audit`)
- **Runner**: Ubuntu Latest
- **Steps**:
  1. Checkout code
  2. Setup Node.js
  3. Run npm audit
  4. Run npm audit fix (dry-run)

**Commands:**
```bash
npm audit --audit-level=moderate
npm audit fix --dry-run
```

#### Job 2: Dependency Review (`dependency-review`)
- **Runner**: Ubuntu Latest
- **Trigger**: Pull requests only
- **Action**: `actions/dependency-review-action@v4`
- **Settings**: Fails on moderate or higher severity

#### Job 3: CodeQL Analysis (`codeql`)
- **Runner**: Ubuntu Latest
- **Language**: JavaScript
- **Steps**:
  1. Initialize CodeQL
  2. Autobuild
  3. Perform analysis

**Purpose**: Detects security vulnerabilities in code

---

## Code Quality Tools

### 1. Solhint (Solidity Linter)

**Configuration**: `.solhint.json`

**Key Rules:**
```json
{
  "code-complexity": ["error", 8],
  "compiler-version": ["error", "^0.8.24"],
  "max-line-length": ["error", 120],
  "named-parameters-mapping": "warn",
  "no-empty-blocks": "error"
}
```

**Run:**
```bash
npm run lint:solidity        # Check
npm run lint:solidity:fix    # Fix
```

**Ignored Files**: `.solhintignore`
- `node_modules/`
- `artifacts/`
- `test/`
- `scripts/`

---

### 2. ESLint (JavaScript Linter)

**Configuration**: `.eslintrc.json`

**Key Rules:**
```json
{
  "no-console": "off",
  "no-unused-vars": ["warn", { "argsIgnorePattern": "^_" }],
  "prefer-const": "error",
  "no-var": "error"
}
```

**Run:**
```bash
npm run lint        # Check
npm run lint:fix    # Fix
```

---

### 3. Prettier (Code Formatter)

**Configuration**: `.prettierrc.json`

**Settings:**
```json
{
  "printWidth": 120,
  "tabWidth": 2,
  "semi": true,
  "singleQuote": false,
  "trailingComma": "es5"
}
```

**Solidity Override:**
```json
{
  "files": "*.sol",
  "options": {
    "tabWidth": 4,
    "printWidth": 120
  }
}
```

**Run:**
```bash
npm run prettier          # Format all
npm run prettier:check    # Check only
```

---

### 4. Codecov (Coverage Reporting)

**Configuration**: `codecov.yml`

**Settings:**
```yaml
coverage:
  status:
    project:
      target: 80%
      threshold: 5%
    patch:
      target: 80%
```

**Upload:**
- Automatic on Node 20.x test runs
- Requires `CODECOV_TOKEN` in GitHub Secrets

**View Reports:**
- https://codecov.io/gh/[username]/[repo]

---

## Configuration Files

### Required Files

| File | Purpose | Location |
|------|---------|----------|
| `.github/workflows/test.yml` | Main test pipeline | `.github/workflows/` |
| `.github/workflows/security.yml` | Security checks | `.github/workflows/` |
| `.solhint.json` | Solidity linter config | Root |
| `.solhintignore` | Solhint ignore rules | Root |
| `.eslintrc.json` | JavaScript linter config | Root |
| `.prettierrc.json` | Formatter config | Root |
| `.prettierignore` | Prettier ignore rules | Root |
| `codecov.yml` | Coverage config | Root |

### Optional Files

| File | Purpose |
|------|---------|
| `.editorconfig` | Editor settings |
| `.nvmrc` | Node version specification |

---

## Setup Instructions

### 1. Initial Setup

```bash
# Clone repository
git clone <repository-url>
cd anonymous-legal-consultation

# Install dependencies
npm install

# Verify setup
npm run ci
```

### 2. Configure GitHub Secrets

Required secrets:

| Secret | Purpose | How to Get |
|--------|---------|------------|
| `CODECOV_TOKEN` | Coverage upload | https://codecov.io |
| `SEPOLIA_RPC_URL` | Testnet deployment | Infura/Alchemy |
| `PRIVATE_KEY` | Deployment key | MetaMask |
| `ETHERSCAN_API_KEY` | Contract verification | Etherscan |

**Add secrets:**
1. Go to repository Settings
2. Navigate to Secrets and variables → Actions
3. Click "New repository secret"
4. Add each secret with its value

### 3. Enable GitHub Actions

1. Go to repository Settings
2. Navigate to Actions → General
3. Enable "Allow all actions and reusable workflows"
4. Save changes

### 4. Enable Codecov

1. Visit https://codecov.io
2. Sign in with GitHub
3. Add repository
4. Copy token
5. Add as `CODECOV_TOKEN` secret

---

## Local Testing

### Run CI Pipeline Locally

```bash
# Full CI pipeline
npm run ci

# CI with coverage
npm run ci:coverage

# Individual checks
npm run prettier:check
npm run lint
npm run lint:solidity
npm run compile
npm run test
npm run test:coverage
```

### Format Code

```bash
# Format all files
npm run format

# Format specific
npm run prettier
npm run lint:fix
npm run lint:solidity:fix
```

### Test on Multiple Node Versions

```bash
# Using nvm (Node Version Manager)
nvm use 18
npm test

nvm use 20
npm test
```

---

## Troubleshooting

### Common Issues

#### 1. Tests Fail Locally but Pass in CI

**Cause**: Different Node versions or environment

**Solution:**
```bash
# Use same Node version as CI
nvm use 20

# Clean install
rm -rf node_modules package-lock.json
npm install

# Run tests
npm test
```

#### 2. Solhint Errors

**Issue**: Solidity linting failures

**Solution:**
```bash
# Check errors
npm run lint:solidity

# Auto-fix
npm run lint:solidity:fix

# Ignore specific files in .solhintignore
echo "test/" >> .solhintignore
```

#### 3. Prettier Formatting Failures

**Issue**: Code not properly formatted

**Solution:**
```bash
# Check formatting
npm run prettier:check

# Auto-format
npm run prettier

# Format specific file
npx prettier --write "contracts/Contract.sol"
```

#### 4. Coverage Upload Fails

**Issue**: Codecov token missing or invalid

**Solution:**
1. Verify `CODECOV_TOKEN` secret exists
2. Check token is valid on codecov.io
3. Re-generate token if needed
4. Update secret in GitHub

#### 5. Dependency Vulnerabilities

**Issue**: npm audit finds vulnerabilities

**Solution:**
```bash
# Check vulnerabilities
npm audit

# Fix automatically
npm audit fix

# Force fix (may break changes)
npm audit fix --force

# Update specific package
npm update <package-name>
```

---

## Best Practices

### 1. Pre-commit Checks

Run before committing:
```bash
npm run format     # Format code
npm run ci         # Run all checks
```

### 2. Pull Request Workflow

1. Create feature branch
   ```bash
   git checkout -b feature/your-feature
   ```

2. Make changes and test
   ```bash
   npm run ci
   ```

3. Commit with descriptive message
   ```bash
   git commit -m "feat: add new feature"
   ```

4. Push and create PR
   ```bash
   git push origin feature/your-feature
   ```

5. Wait for CI to pass
6. Request review
7. Merge after approval

### 3. Branch Protection

Recommended branch protection rules for `main`:

- ✅ Require pull request before merging
- ✅ Require status checks to pass
  - `lint`
  - `test (18.x)`
  - `test (20.x)`
  - `build`
- ✅ Require branches to be up to date
- ✅ Require conversation resolution

---

## Continuous Improvement

### Monitoring

**What to Monitor:**
- ✅ Test pass rate
- ✅ Coverage percentage
- ✅ Build times
- ✅ Security vulnerabilities
- ✅ Dependency updates

**Tools:**
- GitHub Actions dashboard
- Codecov dashboard
- Dependabot alerts
- CodeQL security alerts

### Optimization

**Speed up CI:**
1. Cache dependencies
   ```yaml
   - uses: actions/setup-node@v4
     with:
       cache: 'npm'
   ```

2. Run jobs in parallel
3. Skip unnecessary steps
4. Use matrix testing efficiently

---

## Additional Resources

### Documentation Links

- [GitHub Actions](https://docs.github.com/en/actions)
- [Solhint](https://github.com/protofire/solhint)
- [ESLint](https://eslint.org/)
- [Prettier](https://prettier.io/)
- [Codecov](https://docs.codecov.com/)
- [Hardhat](https://hardhat.org/)

### Example Commands

```bash
# Complete CI locally
npm run ci

# Quick format and lint
npm run format

# Test specific file
npx hardhat test test/AnonymousLegalConsultation.test.js

# Coverage with HTML report
npm run test:coverage
open coverage/index.html

# Gas report
REPORT_GAS=true npm test
```

---

## Summary

### CI/CD Features Implemented

✅ **Automated Testing** - Runs on every push and PR
✅ **Multi-Node Testing** - Tests on Node 18.x and 20.x
✅ **Code Quality** - Solhint, ESLint, Prettier
✅ **Security Scans** - NPM audit, CodeQL, Dependency review
✅ **Coverage Reporting** - Codecov integration
✅ **Gas Reporting** - Automatic on PRs
✅ **Build Verification** - Ensures successful compilation

### Workflow Triggers

- **Push** to `main` or `develop`
- **Pull Requests** to `main` or `develop`
- **Weekly** security scans (Mondays 9 AM UTC)

---

**Last Updated**: January 2025
**Pipeline Version**: 1.0.0
**Status**: ✅ Production Ready
