# API Documentation

## Privacy-Preserving Legal Consultation Platform

Complete API reference for smart contract functions, events, and structures.

---

## Table of Contents

1. [Contract Overview](#contract-overview)
2. [Core Functions](#core-functions)
3. [Admin Functions](#admin-functions)
4. [View Functions](#view-functions)
5. [Events](#events)
6. [Data Structures](#data-structures)
7. [Modifiers](#modifiers)
8. [Usage Examples](#usage-examples)

---

## Contract Overview

**Contract Name**: `AnonymousLegalConsultation`

**Network**: Zama FHEVM (Sepolia Testnet)

**Solidity Version**: ^0.8.24

**License**: MIT

### Key Features

- Fully Homomorphic Encryption (FHE)
- Gateway callback mechanism
- Timeout protection (consultation, response, decryption)
- Automatic refund system
- Privacy-preserving price obfuscation
- Comprehensive security audit logging

---

## Core Functions

### submitConsultation

Submit an anonymous legal consultation with encrypted question.

**Signature:**
```solidity
function submitConsultation(
    uint32 _clientId,
    uint32 _categoryId,
    string calldata _encryptedQuestion
) external payable
```

**Parameters:**
- `_clientId` (uint32): Anonymous client identifier (not linked to wallet)
- `_categoryId` (uint32): Legal category ID (1-8)
  - 1: Civil Law
  - 2: Criminal Law
  - 3: Family Law
  - 4: Corporate Law
  - 5: Employment Law
  - 6: Real Estate Law
  - 7: Immigration Law
  - 8: Tax Law
- `_encryptedQuestion` (string): Encrypted legal question (max 10,000 characters)

**Payable:** Must send at least 0.001 ETH

**Modifiers:**
- `validInput(_categoryId, 1, 8)`
- `rateLimited`

**Returns:** None (emits events)

**Events Emitted:**
- `ConsultationSubmitted(uint256 indexed consultationId, uint256 timestamp, uint256 obfuscatedFee)`
- `SecurityAuditLog("CONSULTATION_SUBMITTED", msg.sender, consultationId, "New consultation")`

**Requirements:**
- `msg.value >= 0.001 ether`
- `bytes(_encryptedQuestion).length > 0`
- `bytes(_encryptedQuestion).length <= 10000`
- `_categoryId >= 1 && _categoryId <= 8`
- Rate limit not exceeded (max 10 per block per address)

**Example:**
```javascript
const tx = await contract.submitConsultation(
    12345,                          // Anonymous client ID
    1,                              // Civil Law
    "0xencrypted_question_data...", // Encrypted question
    { value: ethers.parseEther("0.001") }
);
await tx.wait();
```

---

### registerLawyer

Register as a lawyer with encrypted specialty.

**Signature:**
```solidity
function registerLawyer(uint32 _specialty) external
```

**Parameters:**
- `_specialty` (uint32): Legal specialty (1-8, same as consultation categories)

**Modifiers:**
- `validInput(_specialty, 1, 8)`

**Returns:** None (emits events)

**Events Emitted:**
- `LawyerRegistered(uint256 indexed lawyerId, uint256 timestamp)`
- `SecurityAuditLog("LAWYER_REGISTERED", msg.sender, lawyerId, "New lawyer profile")`

**Requirements:**
- `!registeredLawyers[msg.sender]` (not already registered)
- `_specialty >= 1 && _specialty <= 8`

**Example:**
```javascript
const tx = await contract.registerLawyer(1); // Register for Civil Law
await tx.wait();
```

**Post-Registration:**
- Lawyer must be verified by admin before accepting consultations
- Initial rating: 50/100
- Status: Active but not verified

---

### assignConsultation

Assign a pending consultation to a verified lawyer (admin only).

**Signature:**
```solidity
function assignConsultation(
    uint256 consultationId,
    uint256 lawyerId
) external onlyAdmin consultationExists(consultationId) notTimedOut(consultationId) validInput(lawyerId, 1, lawyerCounter)
```

**Parameters:**
- `consultationId` (uint256): ID of the consultation to assign
- `lawyerId` (uint256): ID of the lawyer to assign to

**Modifiers:**
- `onlyAdmin`
- `consultationExists(consultationId)`
- `notTimedOut(consultationId)`
- `validInput(lawyerId, 1, lawyerCounter)`

**Returns:** None (emits events)

**Events Emitted:**
- `ConsultationAssigned(uint256 indexed consultationId, uint256 indexed lawyerId, uint256 timestamp)`
- `SecurityAuditLog("CONSULTATION_ASSIGNED", msg.sender, consultationId, "Assigned to lawyer")`

**Requirements:**
- `consultation.status == ConsultationStatus.Pending`
- `!consultation.isResolved`
- `lawyers[lawyerId].isActive`
- `lawyers[lawyerId].isVerified`
- `block.timestamp <= consultation.timestamp + CONSULTATION_TIMEOUT` (not timed out)

**Example:**
```javascript
const tx = await contract.assignConsultation(1, 5); // Assign consultation #1 to lawyer #5
await tx.wait();
```

---

### provideResponse

Submit encrypted response to assigned consultation (lawyer only).

**Signature:**
```solidity
function provideResponse(
    uint256 consultationId,
    string calldata _encryptedResponse
) external onlyRegisteredLawyer consultationExists(consultationId) notTimedOut(consultationId)
```

**Parameters:**
- `consultationId` (uint256): ID of the consultation
- `_encryptedResponse` (string): Encrypted response (max 20,000 characters)

**Modifiers:**
- `onlyRegisteredLawyer`
- `consultationExists(consultationId)`
- `notTimedOut(consultationId)`

**Returns:** None (emits events, initiates Gateway callback)

**Events Emitted:**
- `ResponseProvided(uint256 indexed consultationId, uint256 timestamp)`
- `SecurityAuditLog("RESPONSE_PROVIDED", msg.sender, consultationId, "Response submitted")`
- `DecryptionCallbackRequested(uint256 indexed requestId, uint256 indexed consultationId, DecryptionType requestType)`

**Requirements:**
- `bytes(_encryptedResponse).length > 0`
- `bytes(_encryptedResponse).length <= 20000`
- `!consultation.isResolved`
- `consultation.status == ConsultationStatus.Assigned || consultation.status == ConsultationStatus.InProgress`
- `block.timestamp <= consultation.assignedTimestamp + RESPONSE_TIMEOUT` (within 7 days)

**Side Effects:**
- Triggers Gateway decryption request for payment processing
- Updates lawyer consultation count
- Updates consultation status to "Responded"

**Example:**
```javascript
const tx = await contract.provideResponse(
    1,                              // Consultation ID
    "0xencrypted_response_data..."  // Encrypted response
);
await tx.wait();
```

---

### requestRefund

Request refund for timed-out or failed consultation.

**Signature:**
```solidity
function requestRefund(uint256 consultationId) external consultationExists(consultationId)
```

**Parameters:**
- `consultationId` (uint256): ID of the consultation

**Modifiers:**
- `consultationExists(consultationId)`

**Returns:** None (emits events)

**Events Emitted:**
- `RefundRequested(uint256 indexed consultationId, address indexed client, uint256 amount)`
- `SecurityAuditLog("REFUND_REQUESTED", msg.sender, consultationId, "Refund initiated")`

**Requirements:**
- `!consultation.refundProcessed`
- `!consultation.isResolved`
- `consultation.isPaid`
- One of:
  - Consultation timeout (30 days)
  - Response timeout (7 days after assignment)
  - Decryption timeout (1 day after request)
  - Refund already requested (e.g., by decryption failure)

**Example:**
```javascript
// Check eligibility first
const [eligible, reason] = await contract.isRefundEligible(1);
if (eligible) {
    const tx = await contract.requestRefund(1);
    await tx.wait();
}
```

---

## Admin Functions

### verifyLawyer

Verify a registered lawyer to enable consultation assignment.

**Signature:**
```solidity
function verifyLawyer(uint256 lawyerId) external onlyAdmin validInput(lawyerId, 1, lawyerCounter)
```

**Parameters:**
- `lawyerId` (uint256): ID of the lawyer to verify

**Modifiers:**
- `onlyAdmin`
- `validInput(lawyerId, 1, lawyerCounter)`

**Events Emitted:**
- `LawyerVerified(uint256 indexed lawyerId)`
- `SecurityAuditLog("LAWYER_VERIFIED", msg.sender, lawyerId, "Lawyer verified")`

**Example:**
```javascript
const tx = await contract.verifyLawyer(5);
await tx.wait();
```

---

### processRefund

Process approved refund for eligible consultation (admin only).

**Signature:**
```solidity
function processRefund(
    uint256 consultationId,
    address clientAddress
) external onlyAdmin consultationExists(consultationId)
```

**Parameters:**
- `consultationId` (uint256): ID of the consultation
- `clientAddress` (address): Address to send refund to

**Modifiers:**
- `onlyAdmin`
- `consultationExists(consultationId)`

**Returns:** None (transfers funds, emits events)

**Events Emitted:**
- `RefundProcessed(uint256 indexed consultationId, address indexed client, uint256 amount)`
- `SecurityAuditLog("REFUND_PROCESSED", msg.sender, consultationId, "Refund completed")`

**Requirements:**
- `consultation.refundRequested`
- `!consultation.refundProcessed`
- `consultation.isPaid`

**Example:**
```javascript
const tx = await contract.processRefund(1, "0xclientAddress...");
await tx.wait();
```

---

### updateLawyerRating

Update lawyer rating (admin only).

**Signature:**
```solidity
function updateLawyerRating(
    uint256 lawyerId,
    uint32 newRating
) external onlyAdmin validInput(lawyerId, 1, lawyerCounter) validInput(newRating, 0, 100)
```

**Parameters:**
- `lawyerId` (uint256): ID of the lawyer
- `newRating` (uint32): New rating (0-100)

**Modifiers:**
- `onlyAdmin`
- `validInput(lawyerId, 1, lawyerCounter)`
- `validInput(newRating, 0, 100)`

**Events Emitted:**
- `SecurityAuditLog("RATING_UPDATED", msg.sender, lawyerId, "Lawyer rating updated")`

**Example:**
```javascript
const tx = await contract.updateLawyerRating(5, 85); // Set rating to 85/100
await tx.wait();
```

---

### deactivateLawyer

Deactivate a lawyer (prevents new consultations).

**Signature:**
```solidity
function deactivateLawyer(uint256 lawyerId) external onlyAdmin validInput(lawyerId, 1, lawyerCounter)
```

**Parameters:**
- `lawyerId` (uint256): ID of the lawyer to deactivate

**Modifiers:**
- `onlyAdmin`
- `validInput(lawyerId, 1, lawyerCounter)`

**Events Emitted:**
- `SecurityAuditLog("LAWYER_DEACTIVATED", msg.sender, lawyerId, "Lawyer deactivated")`

**Example:**
```javascript
const tx = await contract.deactivateLawyer(5);
await tx.wait();
```

---

### withdrawFees

Withdraw platform fees (admin only).

**Signature:**
```solidity
function withdrawFees(uint256 amount) external onlyAdmin
```

**Parameters:**
- `amount` (uint256): Amount to withdraw (in wei)

**Modifiers:**
- `onlyAdmin`

**Requirements:**
- `amount > 0`
- `amount <= address(this).balance`

**Events Emitted:**
- `SecurityAuditLog("FEES_WITHDRAWN", admin, amount, "Platform fees withdrawn")`

**Example:**
```javascript
const balance = await ethers.provider.getBalance(contractAddress);
const tx = await contract.withdrawFees(balance);
await tx.wait();
```

---

### markTimedOut

Mark consultation as timed out (any user can call).

**Signature:**
```solidity
function markTimedOut(uint256 consultationId) external consultationExists(consultationId)
```

**Parameters:**
- `consultationId` (uint256): ID of the consultation

**Modifiers:**
- `consultationExists(consultationId)`

**Requirements:**
- `!consultation.isResolved`
- `block.timestamp > consultation.timestamp + CONSULTATION_TIMEOUT` (30 days passed)

**Events Emitted:**
- `ConsultationTimedOut(uint256 indexed consultationId, ConsultationStatus previousStatus)`
- `SecurityAuditLog("CONSULTATION_TIMEOUT", msg.sender, consultationId, "Marked as timed out")`

**Example:**
```javascript
const tx = await contract.markTimedOut(1);
await tx.wait();
```

---

## View Functions

### getConsultationDetails

Get consultation details (encrypted data included).

**Signature:**
```solidity
function getConsultationDetails(uint256 consultationId)
    external
    view
    consultationExists(consultationId)
    returns (
        string memory encryptedQuestion,
        string memory encryptedResponse,
        uint256 timestamp,
        bool isResolved,
        bool isPaid,
        ConsultationStatus status,
        bool refundRequested,
        bool refundProcessed
    )
```

**Parameters:**
- `consultationId` (uint256): ID of the consultation

**Returns:**
- `encryptedQuestion` (string): Encrypted question data
- `encryptedResponse` (string): Encrypted response data (empty if not responded)
- `timestamp` (uint256): Submission timestamp
- `isResolved` (bool): Whether consultation is resolved
- `isPaid` (bool): Whether consultation is paid
- `status` (ConsultationStatus): Current status (enum)
- `refundRequested` (bool): Whether refund was requested
- `refundProcessed` (bool): Whether refund was processed

**Example:**
```javascript
const details = await contract.getConsultationDetails(1);
console.log("Status:", details.status);
console.log("Resolved:", details.isResolved);
```

---

### getLawyerProfile

Get lawyer profile information.

**Signature:**
```solidity
function getLawyerProfile(uint256 lawyerId)
    external
    view
    validInput(lawyerId, 1, lawyerCounter)
    returns (
        uint256 consultationCount,
        bool isVerified,
        bool isActive,
        uint256 registrationTimestamp
    )
```

**Parameters:**
- `lawyerId` (uint256): ID of the lawyer

**Returns:**
- `consultationCount` (uint256): Number of completed consultations
- `isVerified` (bool): Whether lawyer is verified
- `isActive` (bool): Whether lawyer is active
- `registrationTimestamp` (uint256): Registration timestamp

**Example:**
```javascript
const profile = await contract.getLawyerProfile(5);
console.log("Verified:", profile.isVerified);
console.log("Consultations:", profile.consultationCount);
```

---

### getClientStats

Get client statistics.

**Signature:**
```solidity
function getClientStats(address clientAddress)
    external
    view
    returns (
        uint256 totalConsultations,
        uint256 lastConsultationTimestamp
    )
```

**Parameters:**
- `clientAddress` (address): Address of the client

**Returns:**
- `totalConsultations` (uint256): Total consultations submitted
- `lastConsultationTimestamp` (uint256): Timestamp of last consultation

**Example:**
```javascript
const stats = await contract.getClientStats("0xclientAddress...");
console.log("Total consultations:", stats.totalConsultations);
```

---

### getSystemStats

Get system-wide statistics.

**Signature:**
```solidity
function getSystemStats()
    external
    view
    returns (
        uint256 totalConsultations,
        uint256 totalLawyers,
        uint256 verifiedLawyers,
        uint256 activeLawyers
    )
```

**Returns:**
- `totalConsultations` (uint256): Total consultations submitted
- `totalLawyers` (uint256): Total lawyers registered
- `verifiedLawyers` (uint256): Number of verified lawyers
- `activeLawyers` (uint256): Number of active lawyers

**Example:**
```javascript
const stats = await contract.getSystemStats();
console.log("Total consultations:", stats.totalConsultations);
console.log("Verified lawyers:", stats.verifiedLawyers);
```

---

### isRefundEligible

Check if consultation is eligible for refund.

**Signature:**
```solidity
function isRefundEligible(uint256 consultationId)
    external
    view
    consultationExists(consultationId)
    returns (bool eligible, string memory reason)
```

**Parameters:**
- `consultationId` (uint256): ID of the consultation

**Returns:**
- `eligible` (bool): Whether refund is eligible
- `reason` (string): Reason for eligibility/ineligibility

**Possible Reasons:**
- "Refund already processed" (not eligible)
- "Consultation resolved" (not eligible)
- "Not paid" (not eligible)
- "Consultation timed out" (eligible)
- "Response timeout" (eligible)
- "Decryption timeout" (eligible)
- "Refund requested" (eligible)
- "Not eligible"

**Example:**
```javascript
const [eligible, reason] = await contract.isRefundEligible(1);
if (eligible) {
    console.log("Refund eligible:", reason);
    // Call requestRefund()
} else {
    console.log("Not eligible:", reason);
}
```

---

### getDecryptionRequest

Get decryption request details.

**Signature:**
```solidity
function getDecryptionRequest(uint256 requestId)
    external
    view
    returns (
        uint256 consultationId,
        address requester,
        uint256 requestTimestamp,
        bool isProcessed,
        DecryptionType requestType
    )
```

**Parameters:**
- `requestId` (uint256): Decryption request ID

**Returns:**
- `consultationId` (uint256): Associated consultation ID
- `requester` (address): Address that initiated request
- `requestTimestamp` (uint256): Request timestamp
- `isProcessed` (bool): Whether request was processed
- `requestType` (DecryptionType): Type of decryption (enum)

**Example:**
```javascript
const request = await contract.getDecryptionRequest(123);
console.log("Consultation ID:", request.consultationId);
console.log("Processed:", request.isProcessed);
```

---

### getLegalCategory

Get legal category name by ID.

**Signature:**
```solidity
function getLegalCategory(uint256 categoryId)
    external
    view
    validInput(categoryId, 1, 8)
    returns (string memory)
```

**Parameters:**
- `categoryId` (uint256): Category ID (1-8)

**Returns:**
- Category name (string)

**Categories:**
1. Civil Law
2. Criminal Law
3. Family Law
4. Corporate Law
5. Employment Law
6. Real Estate Law
7. Immigration Law
8. Tax Law

**Example:**
```javascript
const category = await contract.getLegalCategory(1);
console.log(category); // "Civil Law"
```

---

### isRegisteredLawyer

Check if address is a registered lawyer.

**Signature:**
```solidity
function isRegisteredLawyer(address lawyerAddress) external view returns (bool)
```

**Parameters:**
- `lawyerAddress` (address): Address to check

**Returns:**
- `bool`: True if registered, false otherwise

**Example:**
```javascript
const isLawyer = await contract.isRegisteredLawyer("0xlawyerAddress...");
```

---

### getLawyerIdByAddress

Get lawyer ID by wallet address.

**Signature:**
```solidity
function getLawyerIdByAddress(address lawyerAddress) external view returns (uint256)
```

**Parameters:**
- `lawyerAddress` (address): Lawyer's wallet address

**Returns:**
- `uint256`: Lawyer ID (0 if not registered)

**Example:**
```javascript
const lawyerId = await contract.getLawyerIdByAddress("0xlawyerAddress...");
if (lawyerId > 0) {
    console.log("Lawyer ID:", lawyerId);
}
```

---

## Events

### ConsultationSubmitted

Emitted when a new consultation is submitted.

```solidity
event ConsultationSubmitted(
    uint256 indexed consultationId,
    uint256 timestamp,
    uint256 obfuscatedFee
);
```

**Parameters:**
- `consultationId` (indexed): ID of the new consultation
- `timestamp`: Submission timestamp
- `obfuscatedFee`: Obfuscated fee amount (for privacy)

---

### LawyerRegistered

Emitted when a new lawyer registers.

```solidity
event LawyerRegistered(
    uint256 indexed lawyerId,
    uint256 timestamp
);
```

**Parameters:**
- `lawyerId` (indexed): ID of the new lawyer
- `timestamp`: Registration timestamp

---

### ConsultationAssigned

Emitted when consultation is assigned to a lawyer.

```solidity
event ConsultationAssigned(
    uint256 indexed consultationId,
    uint256 indexed lawyerId,
    uint256 timestamp
);
```

**Parameters:**
- `consultationId` (indexed): ID of the consultation
- `lawyerId` (indexed): ID of the assigned lawyer
- `timestamp`: Assignment timestamp

---

### ResponseProvided

Emitted when lawyer provides a response.

```solidity
event ResponseProvided(
    uint256 indexed consultationId,
    uint256 timestamp
);
```

**Parameters:**
- `consultationId` (indexed): ID of the consultation
- `timestamp`: Response timestamp

---

### RefundRequested

Emitted when refund is requested.

```solidity
event RefundRequested(
    uint256 indexed consultationId,
    address indexed client,
    uint256 amount
);
```

**Parameters:**
- `consultationId` (indexed): ID of the consultation
- `client` (indexed): Address of the client
- `amount`: Refund amount

---

### RefundProcessed

Emitted when refund is processed.

```solidity
event RefundProcessed(
    uint256 indexed consultationId,
    address indexed client,
    uint256 amount
);
```

**Parameters:**
- `consultationId` (indexed): ID of the consultation
- `client` (indexed): Address of the client
- `amount`: Refunded amount

---

### DecryptionCallbackRequested

Emitted when Gateway decryption is requested.

```solidity
event DecryptionCallbackRequested(
    uint256 indexed requestId,
    uint256 indexed consultationId,
    DecryptionType requestType
);
```

**Parameters:**
- `requestId` (indexed): Decryption request ID
- `consultationId` (indexed): Associated consultation ID
- `requestType`: Type of decryption (ConsultationData, ResponseData, PaymentData)

---

### DecryptionCallbackCompleted

Emitted when Gateway callback completes successfully.

```solidity
event DecryptionCallbackCompleted(
    uint256 indexed requestId,
    uint256 indexed consultationId
);
```

**Parameters:**
- `requestId` (indexed): Decryption request ID
- `consultationId` (indexed): Associated consultation ID

---

### DecryptionFailed

Emitted when decryption fails or times out.

```solidity
event DecryptionFailed(
    uint256 indexed requestId,
    uint256 indexed consultationId,
    string reason
);
```

**Parameters:**
- `requestId` (indexed): Decryption request ID
- `consultationId` (indexed): Associated consultation ID
- `reason`: Failure reason

---

### SecurityAuditLog

Emitted for security-critical operations.

```solidity
event SecurityAuditLog(
    string indexed eventType,
    address indexed actor,
    uint256 indexed resourceId,
    string details
);
```

**Parameters:**
- `eventType` (indexed): Type of event (e.g., "CONSULTATION_SUBMITTED")
- `actor` (indexed): Address performing action
- `resourceId` (indexed): Related resource ID
- `details`: Additional details

**Event Types:**
- `CONTRACT_DEPLOYED`
- `CONSULTATION_SUBMITTED`
- `LAWYER_REGISTERED`
- `CONSULTATION_ASSIGNED`
- `RESPONSE_PROVIDED`
- `DECRYPTION_COMPLETED`
- `DECRYPTION_FAILED`
- `REFUND_REQUESTED`
- `REFUND_PROCESSED`
- `CONSULTATION_TIMEOUT`
- `LAWYER_VERIFIED`
- `RATING_UPDATED`
- `LAWYER_DEACTIVATED`
- `FEES_WITHDRAWN`
- `EMERGENCY_STOP`
- `ACCESS_CONTROL`
- `FUNDS_RECEIVED`

---

## Data Structures

### ConsultationStatus (Enum)

```solidity
enum ConsultationStatus {
    Pending,          // 0: Submitted, awaiting assignment
    Assigned,         // 1: Assigned to lawyer
    InProgress,       // 2: Lawyer working on response
    Responded,        // 3: Response submitted, awaiting decryption
    Resolved,         // 4: Payment processed, consultation complete
    TimedOut,         // 5: Timed out
    RefundRequested,  // 6: Refund requested
    Refunded          // 7: Refund processed
}
```

---

### DecryptionType (Enum)

```solidity
enum DecryptionType {
    ConsultationData,  // 0: Decrypt consultation data
    ResponseData,      // 1: Decrypt response data
    PaymentData        // 2: Decrypt payment data
}
```

---

## Modifiers

### onlyAdmin

Restricts function to admin only.

```solidity
modifier onlyAdmin()
```

**Usage:**
```solidity
function verifyLawyer(uint256 lawyerId) external onlyAdmin { }
```

---

### onlyRegisteredLawyer

Restricts function to registered lawyers only.

```solidity
modifier onlyRegisteredLawyer()
```

**Usage:**
```solidity
function provideResponse(...) external onlyRegisteredLawyer { }
```

---

### consultationExists

Validates consultation ID exists.

```solidity
modifier consultationExists(uint256 consultationId)
```

**Usage:**
```solidity
function getConsultationDetails(uint256 consultationId)
    external
    view
    consultationExists(consultationId)
{ }
```

---

### notTimedOut

Validates consultation has not timed out.

```solidity
modifier notTimedOut(uint256 consultationId)
```

**Usage:**
```solidity
function assignConsultation(...)
    external
    notTimedOut(consultationId)
{ }
```

---

### validInput

Validates input is within valid range.

```solidity
modifier validInput(uint256 value, uint256 min, uint256 max)
```

**Usage:**
```solidity
function registerLawyer(uint32 _specialty)
    external
    validInput(_specialty, 1, 8)
{ }
```

---

### rateLimited

Rate limiting to prevent DoS attacks.

```solidity
modifier rateLimited()
```

**Usage:**
```solidity
function submitConsultation(...) external payable rateLimited { }
```

---

## Usage Examples

### Complete Workflow Example

```javascript
const { ethers } = require("ethers");

// Connect to contract
const provider = new ethers.JsonRpcProvider("https://rpc.sepolia.org");
const signer = new ethers.Wallet(privateKey, provider);
const contract = new ethers.Contract(contractAddress, abi, signer);

// 1. Client submits consultation
console.log("Submitting consultation...");
const submitTx = await contract.submitConsultation(
    12345,                          // Anonymous client ID
    1,                              // Civil Law
    "0xencrypted_question...",
    { value: ethers.parseEther("0.001") }
);
await submitTx.wait();
console.log("Consultation submitted!");

// 2. Lawyer registers
console.log("Registering lawyer...");
const registerTx = await contract.connect(lawyerSigner).registerLawyer(1);
await registerTx.wait();
console.log("Lawyer registered!");

// 3. Admin verifies lawyer
console.log("Verifying lawyer...");
const lawyerId = await contract.getLawyerIdByAddress(lawyerAddress);
const verifyTx = await contract.verifyLawyer(lawyerId);
await verifyTx.wait();
console.log("Lawyer verified!");

// 4. Admin assigns consultation
console.log("Assigning consultation...");
const assignTx = await contract.assignConsultation(1, lawyerId);
await assignTx.wait();
console.log("Consultation assigned!");

// 5. Lawyer provides response
console.log("Providing response...");
const responseTx = await contract.connect(lawyerSigner).provideResponse(
    1,
    "0xencrypted_response..."
);
await responseTx.wait();
console.log("Response submitted! Gateway decryption initiated...");

// 6. Check consultation status
const details = await contract.getConsultationDetails(1);
console.log("Status:", details.status);
console.log("Resolved:", details.isResolved);

// 7. If needed, request refund
const [eligible, reason] = await contract.isRefundEligible(1);
if (eligible) {
    console.log("Requesting refund:", reason);
    const refundTx = await contract.requestRefund(1);
    await refundTx.wait();
    console.log("Refund requested!");
}
```

### Event Monitoring Example

```javascript
// Listen for consultation submissions
contract.on("ConsultationSubmitted", (consultationId, timestamp, obfuscatedFee, event) => {
    console.log("New consultation:", consultationId.toString());
    console.log("Timestamp:", new Date(Number(timestamp) * 1000));
});

// Listen for refund requests
contract.on("RefundRequested", (consultationId, client, amount, event) => {
    console.log("Refund requested for consultation:", consultationId.toString());
    console.log("Client:", client);
});

// Listen for security audit logs
contract.on("SecurityAuditLog", (eventType, actor, resourceId, details, event) => {
    console.log("Security event:", eventType);
    console.log("Actor:", actor);
    console.log("Details:", details);
});
```

---

## Constants

```solidity
uint256 public constant CONSULTATION_TIMEOUT = 30 days;
uint256 public constant RESPONSE_TIMEOUT = 7 days;
uint256 public constant DECRYPTION_TIMEOUT = 1 days;
uint256 private constant PRICE_MULTIPLIER = 10000;
uint256 private constant OBFUSCATION_FACTOR = 137;
uint256 private constant MAX_HCU_PER_OPERATION = 100000;
uint256 private constant MAX_CONSULTATIONS_PER_BLOCK = 10;
```

---

## Error Messages

| Error | Meaning |
|-------|---------|
| "Only admin" | Caller is not admin |
| "Must be registered lawyer" | Caller is not a registered lawyer |
| "Invalid consultation ID" | Consultation ID out of range |
| "Consultation timed out" | Consultation exceeded timeout period |
| "Input out of valid range" | Input parameter out of valid range |
| "Rate limit exceeded" | Too many requests in one block |
| "Minimum consultation fee required" | Payment too low (< 0.001 ETH) |
| "Question cannot be empty" | Empty question string |
| "Question too long" | Question > 10,000 characters |
| "Response cannot be empty" | Empty response string |
| "Response too long" | Response > 20,000 characters |
| "Refund already processed" | Cannot request refund twice |
| "Consultation resolved, cannot refund" | Cannot refund completed consultation |
| "Already registered" | Lawyer already registered |
| "Invalid specialty" | Specialty out of range (1-8) |
| "Lawyer not active" | Cannot assign to inactive lawyer |
| "Lawyer not verified" | Cannot assign to unverified lawyer |

---

## Support

For questions or issues:
- GitHub Issues: [Repository Issues](https://github.com/YourRepo/issues)
- Documentation: [Full Documentation](./ARCHITECTURE.md)
- Security: See [SECURITY.md](./SECURITY.md)
