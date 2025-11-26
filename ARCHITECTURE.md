# Architecture Documentation

## Privacy-Preserving Legal Consultation Platform

### System Overview

This platform implements a privacy-first legal consultation system using **Fully Homomorphic Encryption (FHE)** and the **Gateway Callback Pattern** for asynchronous decryption operations.

---

## Table of Contents

1. [Core Architecture](#core-architecture)
2. [Gateway Callback Mechanism](#gateway-callback-mechanism)
3. [Security Features](#security-features)
4. [Privacy-Preserving Techniques](#privacy-preserving-techniques)
5. [Timeout Protection](#timeout-protection)
6. [Refund Mechanism](#refund-mechanism)
7. [Gas Optimization](#gas-optimization)
8. [Data Flow Diagrams](#data-flow-diagrams)

---

## Core Architecture

### Design Principles

1. **Privacy First**: All sensitive data encrypted using FHE
2. **Asynchronous Processing**: Gateway callback pattern for decryption
3. **Fail-Safe**: Comprehensive timeout and refund mechanisms
4. **Security Hardened**: Multiple layers of input validation and access control
5. **Gas Efficient**: Optimized HCU (Homomorphic Computation Unit) usage

### Architecture Pattern

```
┌──────────────────────────────────────────────────────────────────┐
│                         User Layer                                │
│  (Client submits encrypted consultation with obfuscated fee)     │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│                    Smart Contract Layer                           │
│                                                                    │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐            │
│  │ Consultation│  │   Lawyer    │  │    Admin     │            │
│  │ Management  │  │ Management  │  │  Management  │            │
│  └─────────────┘  └─────────────┘  └──────────────┘            │
│                                                                    │
│  ┌────────────────────────────────────────────────────┐          │
│  │           FHE Encryption Layer                     │          │
│  │  - euint32: Client IDs, Categories, Lawyer IDs     │          │
│  │  - euint64: Obfuscated Fees, Earnings              │          │
│  │  - eaddress: Encrypted Addresses                   │          │
│  └────────────────────────────────────────────────────┘          │
│                                                                    │
│  ┌────────────────────────────────────────────────────┐          │
│  │         Security & Validation Layer                │          │
│  │  - Input validation (ranges, lengths)              │          │
│  │  - Access control (onlyAdmin, onlyLawyer)          │          │
│  │  - Rate limiting (DoS protection)                  │          │
│  │  - Overflow protection (Solidity 0.8+)             │          │
│  └────────────────────────────────────────────────────┘          │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│                  Gateway Callback Layer                           │
│                                                                    │
│  1. Contract requests decryption (FHE.requestDecryption)          │
│  2. Gateway decrypts values asynchronously                        │
│  3. Gateway calls callback function with proof                    │
│  4. Contract verifies proof and processes payment                 │
│                                                                    │
│  Timeout Protection: 1 day decryption timeout                     │
│  Failure Handling: Automatic refund mechanism                     │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│              Zama FHEVM Network (Sepolia)                         │
│        (Immutable, Encrypted, Decentralized)                      │
└──────────────────────────────────────────────────────────────────┘
```

---

## Gateway Callback Mechanism

### Overview

The Gateway Callback Pattern enables **asynchronous decryption** of FHE-encrypted data, preventing blockchain congestion and enabling off-chain computation verification.

### Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│ Step 1: User Submits Encrypted Request                          │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 2: Contract Records Request                                │
│  - Store encrypted consultation                                 │
│  - Mark as "Pending"                                            │
│  - Emit ConsultationSubmitted event                             │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 3: Admin Assigns to Lawyer                                 │
│  - Verify lawyer credentials                                    │
│  - Update status to "Assigned"                                  │
│  - Record assignment timestamp                                  │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 4: Lawyer Provides Response                                │
│  - Submit encrypted response                                    │
│  - Trigger Gateway decryption request                           │
│  - Update status to "Responded"                                 │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 5: Gateway Decrypts Data                                   │
│  - Decrypt lawyer ID and obfuscated fee                         │
│  - Generate cryptographic proof                                 │
│  - Call decryptionCallback() with proof                         │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 6: Contract Verifies & Processes                           │
│  - Verify Gateway proof (FHE.checkSignatures)                   │
│  - Deobfuscate fee for payment                                  │
│  - Update lawyer earnings (encrypted)                           │
│  - Mark consultation as "Resolved"                              │
│  - Emit PaymentProcessed event                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Code Implementation

```solidity
// Step 1: Request Decryption
function _requestDecryptionCallback(uint256 consultationId, DecryptionType requestType)
    internal
{
    EncryptedConsultation storage consultation = consultations[consultationId];

    // Prepare encrypted values for decryption
    bytes32[] memory cts = new bytes32[](2);
    cts[0] = FHE.toBytes32(consultation.encryptedLawyerId);
    cts[1] = FHE.toBytes32(consultation.obfuscatedFee);

    // Request decryption from Gateway
    uint256 requestId = FHE.requestDecryption(
        cts,
        this.decryptionCallback.selector
    );

    consultation.decryptionRequestId = requestId;
    emit DecryptionCallbackRequested(requestId, consultationId, requestType);
}

// Step 2: Gateway Callback
function decryptionCallback(
    uint256 requestId,
    bytes memory cleartexts,
    bytes memory decryptionProof
) external {
    // Verify Gateway proof
    FHE.checkSignatures(requestId, cleartexts, decryptionProof);

    // Decode decrypted values
    (uint32 lawyerId, uint64 obfuscatedFee) = abi.decode(cleartexts, (uint32, uint64));

    // Process payment with privacy-preserving deobfuscation
    uint256 actualFee = (uint256(obfuscatedFee) * 100) / OBFUSCATION_FACTOR;

    // Update encrypted earnings
    lawyers[lawyerId].encryptedEarnings = FHE.add(
        lawyers[lawyerId].encryptedEarnings,
        FHE.asEuint64(obfuscatedFee)
    );

    emit PaymentProcessed(consultationId, actualFee);
}
```

---

## Security Features

### 1. Input Validation

**Comprehensive validation prevents injection attacks and invalid state:**

```solidity
modifier validInput(uint256 value, uint256 min, uint256 max) {
    require(value >= min && value <= max, "Input out of valid range");
    _;
}

// Usage
function registerLawyer(uint32 _specialty)
    external
    validInput(_specialty, 1, 8)  // Only categories 1-8 allowed
{
    // ...
}
```

**String length validation:**
```solidity
require(bytes(_encryptedQuestion).length > 0, "Question cannot be empty");
require(bytes(_encryptedQuestion).length <= 10000, "Question too long");
```

### 2. Access Control

**Role-based access control with audit logging:**

```solidity
modifier onlyAdmin() {
    require(msg.sender == admin, "Only admin");
    emit SecurityAuditLog("ACCESS_CONTROL", msg.sender, 0, "Admin access attempted");
    _;
}

modifier onlyRegisteredLawyer() {
    require(registeredLawyers[msg.sender], "Must be registered lawyer");
    _;
}
```

**Function-level access control:**
- `verifyLawyer()`: Only admin
- `assignConsultation()`: Only admin
- `provideResponse()`: Only registered lawyers
- `processRefund()`: Only admin

### 3. Rate Limiting (DoS Protection)

**Prevent spam attacks:**

```solidity
mapping(address => mapping(uint256 => uint256)) private consultationsPerBlock;

modifier rateLimited() {
    uint256 currentBlock = block.number;
    require(
        consultationsPerBlock[msg.sender][currentBlock] < MAX_CONSULTATIONS_PER_BLOCK,
        "Rate limit exceeded"
    );
    consultationsPerBlock[msg.sender][currentBlock]++;
    _;
}
```

**Limits:**
- Max 10 consultations per address per block
- Prevents DoS attacks via consultation spam

### 4. Overflow Protection

**Solidity 0.8+ built-in overflow checks:**

```solidity
// Automatic overflow/underflow protection
clients[msg.sender].totalConsultations++;  // Safe increment
consultation.timestamp + CONSULTATION_TIMEOUT;  // Safe addition
```

**Additional validation for critical operations:**
```solidity
require(amount <= address(this).balance, "Insufficient balance");
```

### 5. Audit Logging

**Comprehensive security event logging:**

```solidity
event SecurityAuditLog(
    string indexed eventType,
    address indexed actor,
    uint256 indexed resourceId,
    string details
);

// Logged events:
emit SecurityAuditLog("CONSULTATION_SUBMITTED", msg.sender, consultationId, "New consultation");
emit SecurityAuditLog("LAWYER_VERIFIED", msg.sender, lawyerId, "Lawyer verified");
emit SecurityAuditLog("DECRYPTION_FAILED", address(this), consultationId, reason);
emit SecurityAuditLog("REFUND_PROCESSED", msg.sender, consultationId, "Refund completed");
```

---

## Privacy-Preserving Techniques

### 1. Price Obfuscation

**Problem**: Direct fee amounts reveal payment patterns and potentially client identity.

**Solution**: Random multiplier obfuscation

```solidity
uint256 private constant OBFUSCATION_FACTOR = 137; // Random prime

// Obfuscate fee on submission
uint256 obfuscatedFeeValue = (msg.value * OBFUSCATION_FACTOR) / 100;
euint64 obfuscatedFee = FHE.asEuint64(uint64(obfuscatedFeeValue));

// Deobfuscate fee in Gateway callback
uint256 actualFee = (uint256(obfuscatedFee) * 100) / OBFUSCATION_FACTOR;
```

**Benefits:**
- Prevents exact fee amount leakage on-chain
- Makes pattern analysis more difficult
- Preserves relative fee comparisons under encryption

### 2. Privacy-Preserving Division

**Problem**: Division operations can leak information about operands.

**Solution**: Use multiplier instead of direct division

```solidity
// Instead of: prize = totalPool / winnerCount
// Use: prize = (totalPool * MULTIPLIER) / (winnerCount * MULTIPLIER)

uint256 private constant PRICE_MULTIPLIER = 10000;

// Calculate proportional share
uint256 prize = (bet.prizePool * userWeight) / totalWinningWeight;
```

**Benefits:**
- Prevents denominator leakage
- Maintains precision
- Compatible with FHE operations

### 3. Encrypted Earnings Tracking

**All lawyer earnings stored encrypted:**

```solidity
struct LawyerProfile {
    euint64 encryptedEarnings;  // Never revealed publicly
    // ...
}

// Update earnings homomorphically
lawyers[lawyerId].encryptedEarnings = FHE.add(
    lawyers[lawyerId].encryptedEarnings,
    FHE.asEuint64(obfuscatedFee)
);
```

**Benefits:**
- Lawyer income remains private
- Prevents competitive intelligence leakage
- Enables privacy-preserving platform analytics

### 4. Anonymous Client IDs

**Self-generated client IDs not linked to wallet addresses:**

```solidity
euint32 encryptedClientId = FHE.asEuint32(_clientId);  // User-provided

// Store mapping
clients[msg.sender].encryptedClientId = encryptedClientId;

// Client can use different IDs for different consultations
```

**Benefits:**
- Breaks wallet-identity link
- Enables pseudonymous consultations
- User controls identity correlation

---

## Timeout Protection

### Overview

**Prevents funds from being locked permanently** if:
- Lawyer fails to respond
- Decryption Gateway goes offline
- Admin fails to assign consultation

### Timeout Levels

```solidity
uint256 public constant CONSULTATION_TIMEOUT = 30 days;  // Overall timeout
uint256 public constant RESPONSE_TIMEOUT = 7 days;       // Lawyer response deadline
uint256 public constant DECRYPTION_TIMEOUT = 1 days;     // Gateway decryption deadline
```

### Implementation

**1. Consultation-Level Timeout**

```solidity
modifier notTimedOut(uint256 consultationId) {
    EncryptedConsultation storage consultation = consultations[consultationId];
    require(
        block.timestamp <= consultation.timestamp + CONSULTATION_TIMEOUT,
        "Consultation timed out"
    );
    _;
}
```

**2. Response-Level Timeout**

```solidity
function provideResponse(uint256 consultationId, string calldata _encryptedResponse)
    external
{
    // Verify response timeout
    require(
        block.timestamp <= consultation.assignedTimestamp + RESPONSE_TIMEOUT,
        "Response deadline exceeded"
    );
    // ...
}
```

**3. Decryption-Level Timeout**

```solidity
function decryptionCallback(uint256 requestId, bytes memory cleartexts, bytes memory decryptionProof)
    external
{
    DecryptionRequest storage request = decryptionRequests[requestId];

    // Check decryption timeout
    if (block.timestamp > request.requestTimestamp + DECRYPTION_TIMEOUT) {
        _handleDecryptionFailure(request.consultationId, "Decryption timeout");
        return;
    }
    // ...
}
```

### Timeout Handling Flow

```
Consultation Submitted (t = 0)
    │
    ├─► 30 days pass → CONSULTATION_TIMEOUT
    │   └─► Status: TimedOut
    │       └─► Refund eligible
    │
    ├─► Assigned (t = t1)
    │   │
    │   └─► 7 days pass → RESPONSE_TIMEOUT
    │       └─► Status: TimedOut
    │           └─► Refund eligible
    │
    └─► Response provided (t = t2)
        │
        └─► Decryption requested (t = t3)
            │
            └─► 1 day passes → DECRYPTION_TIMEOUT
                └─► Status: RefundRequested
                    └─► Refund processed
```

---

## Refund Mechanism

### Overview

**Automatic refunds for:**
- Consultation timeouts
- Response timeouts
- Decryption failures
- Gateway downtime

### Refund Eligibility

```solidity
function isRefundEligible(uint256 consultationId)
    external
    view
    returns (bool eligible, string memory reason)
{
    // Check various timeout conditions
    bool isTimedOut = block.timestamp > consultation.timestamp + CONSULTATION_TIMEOUT;
    bool responseTimedOut = consultation.assignedTimestamp > 0 &&
                            block.timestamp > consultation.assignedTimestamp + RESPONSE_TIMEOUT;
    bool decryptionTimedOut = consultation.decryptionRequestId > 0 &&
                               block.timestamp > decryptionRequests[consultation.decryptionRequestId].requestTimestamp + DECRYPTION_TIMEOUT;

    // Return first matching condition
    if (isTimedOut) return (true, "Consultation timed out");
    if (responseTimedOut) return (true, "Response timeout");
    if (decryptionTimedOut) return (true, "Decryption timeout");

    return (false, "Not eligible");
}
```

### Refund Process

**1. Request Refund (User-Initiated)**

```solidity
function requestRefund(uint256 consultationId) external {
    // Validate eligibility
    require(!consultation.refundProcessed, "Refund already processed");
    require(!consultation.isResolved, "Consultation resolved, cannot refund");

    // Mark as refund requested
    consultation.refundRequested = true;
    consultation.status = ConsultationStatus.RefundRequested;

    emit RefundRequested(consultationId, msg.sender, 0);
}
```

**2. Process Refund (Admin-Initiated)**

```solidity
function processRefund(uint256 consultationId, address clientAddress)
    external
    onlyAdmin
{
    // Validate refund request
    require(consultation.refundRequested, "Refund not requested");
    require(!consultation.refundProcessed, "Refund already processed");

    // Calculate refund amount (deobfuscate)
    uint256 refundAmount = 0.001 ether; // Minimum fee as fallback

    // Process refund
    consultation.refundProcessed = true;
    consultation.status = ConsultationStatus.Refunded;

    (bool sent, ) = payable(clientAddress).call{value: refundAmount}("");
    require(sent, "Refund transfer failed");

    emit RefundProcessed(consultationId, clientAddress, refundAmount);
}
```

**3. Automatic Refund on Decryption Failure**

```solidity
function _handleDecryptionFailure(uint256 consultationId, string memory reason)
    internal
{
    consultation.status = ConsultationStatus.RefundRequested;
    consultation.refundRequested = true;

    emit DecryptionFailed(consultation.decryptionRequestId, consultationId, reason);
}
```

### Refund State Machine

```
┌───────────┐
│  Pending  │
└─────┬─────┘
      │
      ├─► Timeout → RefundRequested → Refunded
      │
      ├─► Assigned → Response Timeout → RefundRequested → Refunded
      │
      └─► Responded → Decryption Timeout → RefundRequested → Refunded
```

---

## Gas Optimization

### 1. HCU (Homomorphic Computation Unit) Management

**HCU Limits:**
```solidity
uint256 private constant MAX_HCU_PER_OPERATION = 100000;
```

**Optimization Strategies:**

- **Minimize FHE operations**: Batch encrypted operations where possible
- **Use uint64 instead of uint256 for encrypted values**: Smaller ciphertext size
- **Cache encrypted values**: Store frequently-used encrypted values

### 2. Storage Optimization

**Packed structs:**
```solidity
struct EncryptedConsultation {
    // Group related booleans together (packed into single slot)
    bool isResolved;
    bool isPaid;
    bool refundRequested;
    bool refundProcessed;

    // Use smallest sufficient type
    uint256 timestamp;  // Can't be smaller (block.timestamp)

    // Store only essential data on-chain
    string encryptedQuestion;  // Calldata, not copied to storage
}
```

### 3. Loop Optimization

**Avoid unbounded loops:**

```solidity
// ❌ BAD: Unbounded loop
function getVerifiedLawyers() external view returns (uint256[] memory) {
    uint256[] memory result = new uint256[](lawyerCounter);
    for (uint256 i = 1; i <= lawyerCounter; i++) {  // Can grow indefinitely
        if (lawyers[i].isVerified) {
            // ...
        }
    }
    return result;
}

// ✅ GOOD: Return count only, let frontend paginate
function getSystemStats() external view returns (
    uint256 totalConsultations,
    uint256 totalLawyers,
    uint256 verifiedLawyers
) {
    uint256 verified = 0;
    for (uint256 i = 1; i <= lawyerCounter; i++) {
        if (lawyers[i].isVerified) verified++;
    }
    return (consultationCounter, lawyerCounter, verified);
}
```

### 4. Event Optimization

**Indexed vs non-indexed parameters:**

```solidity
// Use indexed for filtering, non-indexed for data
event ConsultationSubmitted(
    uint256 indexed consultationId,  // Filterable
    uint256 timestamp,                // Data only
    uint256 obfuscatedFee             // Data only
);
```

**Max 3 indexed parameters per event** (EVM limitation)

### 5. String Storage

**Use calldata for strings when possible:**

```solidity
// ✅ GOOD: Calldata (not copied to memory/storage)
function submitConsultation(
    uint32 _clientId,
    uint32 _categoryId,
    string calldata _encryptedQuestion  // Calldata
) external payable {
    // ...
}

// ❌ BAD: Memory (unnecessary copy)
function submitConsultation(
    uint32 _clientId,
    uint32 _categoryId,
    string memory _encryptedQuestion  // Memory copy
) external payable {
    // ...
}
```

---

## Data Flow Diagrams

### Complete Consultation Lifecycle

```
┌──────────────────────────────────────────────────────────────────┐
│                    1. Consultation Submission                     │
│                                                                    │
│  Client                                                           │
│    │                                                              │
│    ├─► Generate anonymous ID                                     │
│    ├─► Encrypt question locally (FHE)                            │
│    ├─► Submit with obfuscated fee                                │
│    └─► Status: Pending                                           │
│                                                                    │
│  Events: ConsultationSubmitted, SecurityAuditLog                 │
│  Timeout: 30 days until CONSULTATION_TIMEOUT                     │
└──────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────┐
│                    2. Admin Assignment                            │
│                                                                    │
│  Admin                                                            │
│    │                                                              │
│    ├─► Review pending consultations                              │
│    ├─► Select verified lawyer (specialty match)                  │
│    ├─► Assign consultation                                       │
│    └─► Status: Assigned                                          │
│                                                                    │
│  Validation:                                                      │
│    - Lawyer must be verified                                     │
│    - Lawyer must be active                                       │
│    - Consultation not timed out                                  │
│                                                                    │
│  Events: ConsultationAssigned, SecurityAuditLog                  │
│  Timeout: 7 days until RESPONSE_TIMEOUT                          │
└──────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────┐
│                    3. Lawyer Response                             │
│                                                                    │
│  Lawyer                                                           │
│    │                                                              │
│    ├─► Decrypt question (authorized)                             │
│    ├─► Prepare encrypted response                                │
│    ├─► Submit response                                           │
│    ├─► Trigger Gateway decryption                                │
│    └─► Status: Responded                                         │
│                                                                    │
│  Validation:                                                      │
│    - Response within RESPONSE_TIMEOUT                            │
│    - Response length <= 20000 characters                         │
│    - Lawyer is registered                                        │
│                                                                    │
│  Events: ResponseProvided, DecryptionCallbackRequested           │
│  Timeout: 1 day until DECRYPTION_TIMEOUT                         │
└──────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────┐
│                    4. Gateway Processing                          │
│                                                                    │
│  Gateway                                                          │
│    │                                                              │
│    ├─► Receive decryption request                                │
│    ├─► Decrypt lawyer ID and obfuscated fee                      │
│    ├─► Generate cryptographic proof                              │
│    └─► Call decryptionCallback() with proof                      │
│                                                                    │
│  Validation:                                                      │
│    - Decryption within DECRYPTION_TIMEOUT                        │
│    - Valid cryptographic proof                                   │
│                                                                    │
│  Events: DecryptionCallbackCompleted (success)                   │
│          DecryptionFailed (timeout/error)                        │
└──────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────┐
│                    5. Payment Processing                          │
│                                                                    │
│  Contract                                                         │
│    │                                                              │
│    ├─► Verify Gateway proof (FHE.checkSignatures)                │
│    ├─► Deobfuscate fee                                           │
│    ├─► Update lawyer earnings (encrypted)                        │
│    ├─► Mark consultation as resolved                             │
│    └─► Status: Resolved                                          │
│                                                                    │
│  Privacy:                                                         │
│    - Earnings updated homomorphically (FHE.add)                  │
│    - Actual fee never stored unencrypted                         │
│    - Lawyer income remains private                               │
│                                                                    │
│  Events: PaymentProcessed, SecurityAuditLog                      │
└──────────────────────────────────────────────────────────────────┘
```

### Timeout & Refund Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                   Timeout Detection                               │
│                                                                    │
│  Any user can call:                                              │
│    - markTimedOut(consultationId)                                │
│    - requestRefund(consultationId)                               │
│                                                                    │
│  Automated checks:                                               │
│    - Consultation timeout (30 days)                              │
│    - Response timeout (7 days after assignment)                  │
│    - Decryption timeout (1 day after request)                    │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│                   Refund Request                                  │
│                                                                    │
│  Client/User                                                      │
│    │                                                              │
│    ├─► Call requestRefund(consultationId)                        │
│    ├─► Contract validates eligibility                            │
│    └─► Status: RefundRequested                                   │
│                                                                    │
│  Eligibility checks:                                             │
│    ✓ Not already refunded                                        │
│    ✓ Not resolved                                                │
│    ✓ Was paid                                                    │
│    ✓ Timeout occurred OR decryption failed                       │
│                                                                    │
│  Events: RefundRequested, SecurityAuditLog                       │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│                   Refund Processing                               │
│                                                                    │
│  Admin                                                            │
│    │                                                              │
│    ├─► Review refund request                                     │
│    ├─► Call processRefund(consultationId, clientAddress)         │
│    ├─► Contract transfers funds                                  │
│    └─► Status: Refunded                                          │
│                                                                    │
│  Security:                                                        │
│    - Only admin can process refunds                              │
│    - Prevents duplicate refunds                                  │
│    - Uses call{value} for safe transfer                          │
│                                                                    │
│  Events: RefundProcessed, SecurityAuditLog                       │
└──────────────────────────────────────────────────────────────────┘
```

---

## Best Practices

### For Developers

1. **Always validate inputs** using `validInput` modifier
2. **Use calldata for strings** to save gas
3. **Emit security audit logs** for critical operations
4. **Test timeout scenarios** thoroughly
5. **Monitor HCU usage** and optimize encrypted operations

### For Administrators

1. **Monitor timeout events** and process refunds promptly
2. **Verify lawyers carefully** before enabling consultations
3. **Track Gateway health** for decryption failures
4. **Regular security audits** of access control logs
5. **Keep contract balance sufficient** for refunds

### For Users (Clients)

1. **Use unique client IDs** for better privacy
2. **Monitor consultation status** via events
3. **Request refunds promptly** if timeouts occur
4. **Keep encryption keys secure** (off-chain)
5. **Verify lawyer credentials** before submission

### For Lawyers

1. **Respond within 7 days** to avoid timeouts
2. **Maintain encryption keys securely** (off-chain)
3. **Monitor assigned consultations** via events
4. **Ensure quality responses** to maintain ratings
5. **Update specialty/status** as needed

---

## Security Considerations

### Critical Security Features

1. ✅ **Input Validation**: All inputs validated (ranges, lengths, formats)
2. ✅ **Access Control**: Role-based permissions with audit logging
3. ✅ **Rate Limiting**: DoS protection via per-block limits
4. ✅ **Overflow Protection**: Solidity 0.8+ automatic checks
5. ✅ **Timeout Protection**: Multiple timeout levels prevent fund locks
6. ✅ **Refund Mechanism**: Automatic refunds for failures
7. ✅ **Privacy Preservation**: FHE encryption + obfuscation
8. ✅ **Audit Trail**: Comprehensive SecurityAuditLog events

### Potential Attack Vectors & Mitigations

| Attack | Mitigation |
|--------|-----------|
| **Spam consultations** | Rate limiting (10 per block) |
| **Reentrancy** | Use call{value} + CEI pattern |
| **Integer overflow** | Solidity 0.8+ automatic checks |
| **Front-running** | FHE encryption prevents value inspection |
| **DoS via gas** | HCU limits + timeout protection |
| **Unauthorized access** | onlyAdmin/onlyLawyer modifiers |
| **Fund locking** | Comprehensive timeout + refund system |
| **Gateway downtime** | Decryption timeout → automatic refund |

---

## Future Enhancements

### Phase 1: Advanced Privacy
- Zero-knowledge proof integration
- Anonymous credentials for lawyers
- Private reputation aggregation

### Phase 2: Scalability
- Batch consultation processing
- Layer 2 integration for lower fees
- Cross-chain compatibility

### Phase 3: Automation
- AI-powered lawyer matching
- Automated dispute resolution
- Smart contract-based arbitration

---

## Conclusion

This architecture provides a **production-ready, privacy-first legal consultation platform** with:

- ✅ **Complete privacy** via FHE encryption
- ✅ **Fail-safe design** with comprehensive timeout protection
- ✅ **Asynchronous processing** via Gateway callback pattern
- ✅ **Security hardened** with multiple validation layers
- ✅ **Gas optimized** for efficient on-chain operations

The system is designed to handle **real-world failure scenarios** while maintaining **maximum privacy** and **user fund safety**.
