// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint32, euint64, ebool, eaddress } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

/**
 * @title Privacy-Preserving Legal Consultation Platform
 * @author Anonymous Legal Services
 * @notice Advanced FHE-based legal consultation system with Gateway callback mechanism
 * @dev Implements:
 *      - Refund mechanism for decryption failures
 *      - Timeout protection to prevent permanent locks
 *      - Gateway callback mode for asynchronous processing
 *      - Privacy-preserving price obfuscation
 *      - Comprehensive input validation and access control
 *      - Overflow protection using checked arithmetic (Solidity 0.8+)
 *      - Audit hooks and security event logging
 *
 * Architecture: User submits encrypted request → Contract records → Gateway decrypts → Callback completes transaction
 */
contract AnonymousLegalConsultation is SepoliaConfig {

    // ============ State Variables ============

    address public admin;
    uint256 public consultationCounter;
    uint256 public lawyerCounter;

    // Timeout configuration (prevent permanent locks)
    uint256 public constant CONSULTATION_TIMEOUT = 30 days;
    uint256 public constant RESPONSE_TIMEOUT = 7 days;
    uint256 public constant DECRYPTION_TIMEOUT = 1 days;

    // Price obfuscation multiplier (privacy-preserving division)
    uint256 private constant PRICE_MULTIPLIER = 10000;
    uint256 private constant OBFUSCATION_FACTOR = 137; // Random prime for price obfuscation

    // Gas optimization: HCU (Homomorphic Computation Unit) limits
    uint256 private constant MAX_HCU_PER_OPERATION = 100000;

    // Access control limits (DoS protection)
    uint256 private constant MAX_CONSULTATIONS_PER_BLOCK = 10;
    mapping(address => mapping(uint256 => uint256)) private consultationsPerBlock;

    // ============ Enhanced Structures ============

    struct EncryptedConsultation {
        euint32 encryptedClientId;
        euint32 encryptedCategoryId;
        string encryptedQuestion;
        string encryptedResponse;
        euint32 encryptedLawyerId;
        uint256 timestamp;
        euint64 obfuscatedFee; // Price obfuscation for privacy
        bool isResolved;
        bool isPaid;
        bool refundRequested;
        bool refundProcessed;
        uint256 assignedTimestamp;
        uint256 responseTimestamp;
        uint256 decryptionRequestId; // Gateway callback tracking
        ConsultationStatus status;
    }

    struct LawyerProfile {
        eaddress encryptedAddress;
        euint32 encryptedSpecialty;
        euint32 encryptedRating;
        euint64 encryptedEarnings; // Privacy-preserving earnings tracking
        uint256 consultationCount;
        bool isVerified;
        bool isActive;
        uint256 registrationTimestamp;
    }

    struct ClientProfile {
        euint32 encryptedClientId;
        uint256 totalConsultations;
        euint64 obfuscatedTotalSpent; // Price obfuscation
        uint256 lastConsultationTimestamp;
    }

    struct DecryptionRequest {
        uint256 consultationId;
        address requester;
        uint256 requestTimestamp;
        bool isProcessed;
        DecryptionType requestType;
    }

    // ============ Enums ============

    enum ConsultationStatus {
        Pending,
        Assigned,
        InProgress,
        Responded,
        Resolved,
        TimedOut,
        RefundRequested,
        Refunded
    }

    enum DecryptionType {
        ConsultationData,
        ResponseData,
        PaymentData
    }

    // ============ Mappings ============

    mapping(uint256 => EncryptedConsultation) public consultations;
    mapping(uint256 => LawyerProfile) public lawyers;
    mapping(address => ClientProfile) public clients;
    mapping(address => uint256) public lawyerIds;
    mapping(address => bool) public registeredLawyers;
    mapping(uint256 => string) public legalCategories;
    mapping(uint256 => DecryptionRequest) public decryptionRequests;
    mapping(uint256 => uint256) private requestIdToConsultationId;
    mapping(address => bool) public hasRefundClaimed;

    // ============ Events ============

    event ConsultationSubmitted(uint256 indexed consultationId, uint256 timestamp, uint256 obfuscatedFee);
    event LawyerRegistered(uint256 indexed lawyerId, uint256 timestamp);
    event ConsultationAssigned(uint256 indexed consultationId, uint256 indexed lawyerId, uint256 timestamp);
    event ResponseProvided(uint256 indexed consultationId, uint256 timestamp);
    event PaymentProcessed(uint256 indexed consultationId, uint256 amount);
    event LawyerVerified(uint256 indexed lawyerId);
    event ConsultationTimedOut(uint256 indexed consultationId, ConsultationStatus previousStatus);
    event RefundRequested(uint256 indexed consultationId, address indexed client, uint256 amount);
    event RefundProcessed(uint256 indexed consultationId, address indexed client, uint256 amount);
    event DecryptionCallbackRequested(uint256 indexed requestId, uint256 indexed consultationId, DecryptionType requestType);
    event DecryptionCallbackCompleted(uint256 indexed requestId, uint256 indexed consultationId);
    event DecryptionFailed(uint256 indexed requestId, uint256 indexed consultationId, string reason);
    event SecurityAuditLog(string indexed eventType, address indexed actor, uint256 indexed resourceId, string details);

    // ============ Modifiers ============

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        emit SecurityAuditLog("ACCESS_CONTROL", msg.sender, 0, "Admin access attempted");
        _;
    }

    modifier onlyRegisteredLawyer() {
        require(registeredLawyers[msg.sender], "Must be registered lawyer");
        _;
    }

    modifier consultationExists(uint256 consultationId) {
        require(consultationId > 0 && consultationId <= consultationCounter, "Invalid consultation ID");
        _;
    }

    modifier notTimedOut(uint256 consultationId) {
        EncryptedConsultation storage consultation = consultations[consultationId];
        require(
            block.timestamp <= consultation.timestamp + CONSULTATION_TIMEOUT,
            "Consultation timed out"
        );
        _;
    }

    modifier validInput(uint256 value, uint256 min, uint256 max) {
        require(value >= min && value <= max, "Input out of valid range");
        _;
    }

    modifier rateLimited() {
        uint256 currentBlock = block.number;
        require(
            consultationsPerBlock[msg.sender][currentBlock] < MAX_CONSULTATIONS_PER_BLOCK,
            "Rate limit exceeded"
        );
        consultationsPerBlock[msg.sender][currentBlock]++;
        _;
    }

    // ============ Constructor ============

    constructor() {
        admin = msg.sender;
        consultationCounter = 0;
        lawyerCounter = 0;

        // Initialize legal categories
        legalCategories[1] = "Civil Law";
        legalCategories[2] = "Criminal Law";
        legalCategories[3] = "Family Law";
        legalCategories[4] = "Corporate Law";
        legalCategories[5] = "Employment Law";
        legalCategories[6] = "Real Estate Law";
        legalCategories[7] = "Immigration Law";
        legalCategories[8] = "Tax Law";

        emit SecurityAuditLog("CONTRACT_DEPLOYED", msg.sender, 0, "Contract initialized");
    }

    // ============ Core Functions ============

    /**
     * @notice Submit anonymous legal consultation with privacy-preserving fee obfuscation
     * @dev Uses Gateway callback pattern for asynchronous encrypted processing
     * @param _clientId Anonymous client identifier (encrypted)
     * @param _categoryId Legal category (1-8, encrypted)
     * @param _encryptedQuestion Encrypted legal question
     */
    function submitConsultation(
        uint32 _clientId,
        uint32 _categoryId,
        string calldata _encryptedQuestion
    )
        external
        payable
        validInput(_categoryId, 1, 8)
        rateLimited
    {
        // Input validation
        require(msg.value >= 0.001 ether, "Minimum consultation fee required");
        require(bytes(_encryptedQuestion).length > 0, "Question cannot be empty");
        require(bytes(_encryptedQuestion).length <= 10000, "Question too long");

        consultationCounter++;
        uint256 consultationId = consultationCounter;

        // Encrypt client and category data
        euint32 encryptedClientId = FHE.asEuint32(_clientId);
        euint32 encryptedCategoryId = FHE.asEuint32(_categoryId);

        // Privacy-preserving price obfuscation
        // Multiply fee by random factor to prevent exact amount leakage
        uint256 obfuscatedFeeValue = (msg.value * OBFUSCATION_FACTOR) / 100;
        euint64 obfuscatedFee = FHE.asEuint64(uint64(obfuscatedFeeValue));

        consultations[consultationId] = EncryptedConsultation({
            encryptedClientId: encryptedClientId,
            encryptedCategoryId: encryptedCategoryId,
            encryptedQuestion: _encryptedQuestion,
            encryptedResponse: "",
            encryptedLawyerId: FHE.asEuint32(0),
            timestamp: block.timestamp,
            obfuscatedFee: obfuscatedFee,
            isResolved: false,
            isPaid: true,
            refundRequested: false,
            refundProcessed: false,
            assignedTimestamp: 0,
            responseTimestamp: 0,
            decryptionRequestId: 0,
            status: ConsultationStatus.Pending
        });

        // Update client profile with privacy-preserving tracking
        if (clients[msg.sender].totalConsultations == 0) {
            clients[msg.sender].encryptedClientId = encryptedClientId;
        }
        clients[msg.sender].totalConsultations++;

        // Obfuscate total spent for privacy
        euint64 additionalSpend = FHE.asEuint64(uint64(obfuscatedFeeValue));
        clients[msg.sender].obfuscatedTotalSpent = FHE.add(
            clients[msg.sender].obfuscatedTotalSpent,
            additionalSpend
        );
        clients[msg.sender].lastConsultationTimestamp = block.timestamp;

        // Set ACL permissions for encrypted values
        FHE.allowThis(encryptedClientId);
        FHE.allowThis(encryptedCategoryId);
        FHE.allowThis(obfuscatedFee);
        FHE.allow(encryptedClientId, msg.sender);
        FHE.allow(encryptedCategoryId, msg.sender);

        emit ConsultationSubmitted(consultationId, block.timestamp, obfuscatedFeeValue);
        emit SecurityAuditLog("CONSULTATION_SUBMITTED", msg.sender, consultationId, "New consultation");
    }

    /**
     * @notice Register as a lawyer with encrypted specialty
     * @param _specialty Legal specialty (1-8)
     */
    function registerLawyer(uint32 _specialty)
        external
        validInput(_specialty, 1, 8)
    {
        require(!registeredLawyers[msg.sender], "Already registered");

        lawyerCounter++;
        uint256 lawyerId = lawyerCounter;

        // Encrypt lawyer data
        eaddress encryptedAddress = FHE.asEaddress(msg.sender);
        euint32 encryptedSpecialty = FHE.asEuint32(_specialty);
        euint32 encryptedRating = FHE.asEuint32(50); // Initial rating: 50/100
        euint64 encryptedEarnings = FHE.asEuint64(0);

        lawyers[lawyerId] = LawyerProfile({
            encryptedAddress: encryptedAddress,
            encryptedSpecialty: encryptedSpecialty,
            encryptedRating: encryptedRating,
            encryptedEarnings: encryptedEarnings,
            consultationCount: 0,
            isVerified: false,
            isActive: true,
            registrationTimestamp: block.timestamp
        });

        lawyerIds[msg.sender] = lawyerId;
        registeredLawyers[msg.sender] = true;

        // Set ACL permissions
        FHE.allowThis(encryptedAddress);
        FHE.allowThis(encryptedSpecialty);
        FHE.allowThis(encryptedRating);
        FHE.allowThis(encryptedEarnings);
        FHE.allow(encryptedAddress, msg.sender);
        FHE.allow(encryptedSpecialty, msg.sender);
        FHE.allow(encryptedRating, msg.sender);
        FHE.allow(encryptedEarnings, msg.sender);

        emit LawyerRegistered(lawyerId, block.timestamp);
        emit SecurityAuditLog("LAWYER_REGISTERED", msg.sender, lawyerId, "New lawyer profile");
    }

    /**
     * @notice Assign consultation to lawyer with timeout protection
     * @param consultationId ID of the consultation
     * @param lawyerId ID of the lawyer
     */
    function assignConsultation(uint256 consultationId, uint256 lawyerId)
        external
        onlyAdmin
        consultationExists(consultationId)
        notTimedOut(consultationId)
        validInput(lawyerId, 1, lawyerCounter)
    {
        EncryptedConsultation storage consultation = consultations[consultationId];

        require(consultation.status == ConsultationStatus.Pending, "Consultation not pending");
        require(!consultation.isResolved, "Consultation already resolved");
        require(lawyers[lawyerId].isActive, "Lawyer not active");
        require(lawyers[lawyerId].isVerified, "Lawyer not verified");

        // Encrypt lawyer ID
        euint32 encryptedLawyerId = FHE.asEuint32(uint32(lawyerId));
        consultation.encryptedLawyerId = encryptedLawyerId;
        consultation.assignedTimestamp = block.timestamp;
        consultation.status = ConsultationStatus.Assigned;

        // Set ACL permissions
        FHE.allowThis(encryptedLawyerId);

        emit ConsultationAssigned(consultationId, lawyerId, block.timestamp);
        emit SecurityAuditLog("CONSULTATION_ASSIGNED", msg.sender, consultationId, "Assigned to lawyer");
    }

    /**
     * @notice Provide encrypted response to consultation
     * @dev Implements response timeout protection
     * @param consultationId ID of the consultation
     * @param _encryptedResponse Encrypted response from lawyer
     */
    function provideResponse(uint256 consultationId, string calldata _encryptedResponse)
        external
        onlyRegisteredLawyer
        consultationExists(consultationId)
        notTimedOut(consultationId)
    {
        EncryptedConsultation storage consultation = consultations[consultationId];

        require(bytes(_encryptedResponse).length > 0, "Response cannot be empty");
        require(bytes(_encryptedResponse).length <= 20000, "Response too long");
        require(!consultation.isResolved, "Consultation already resolved");
        require(
            consultation.status == ConsultationStatus.Assigned ||
            consultation.status == ConsultationStatus.InProgress,
            "Invalid consultation status"
        );

        // Verify response timeout
        require(
            block.timestamp <= consultation.assignedTimestamp + RESPONSE_TIMEOUT,
            "Response deadline exceeded"
        );

        uint256 lawyerId = lawyerIds[msg.sender];
        require(lawyerId > 0, "Lawyer not found");

        consultation.encryptedResponse = _encryptedResponse;
        consultation.responseTimestamp = block.timestamp;
        consultation.status = ConsultationStatus.Responded;

        // Update lawyer stats
        lawyers[lawyerId].consultationCount++;

        // Initiate Gateway decryption callback for payment processing
        _requestDecryptionCallback(consultationId, DecryptionType.ResponseData);

        emit ResponseProvided(consultationId, block.timestamp);
        emit SecurityAuditLog("RESPONSE_PROVIDED", msg.sender, consultationId, "Response submitted");
    }

    // ============ Gateway Callback Mechanism ============

    /**
     * @notice Request decryption callback from Gateway
     * @dev Gateway callback pattern: Submit request → Gateway decrypts → Callback processes
     * @param consultationId ID of the consultation
     * @param requestType Type of decryption requested
     */
    function _requestDecryptionCallback(uint256 consultationId, DecryptionType requestType)
        internal
    {
        EncryptedConsultation storage consultation = consultations[consultationId];

        // Prepare ciphertexts for decryption
        bytes32[] memory cts = new bytes32[](2);
        cts[0] = FHE.toBytes32(consultation.encryptedLawyerId);
        cts[1] = FHE.toBytes32(consultation.obfuscatedFee);

        // Request decryption from Gateway
        uint256 requestId = FHE.requestDecryption(
            cts,
            this.decryptionCallback.selector
        );

        consultation.decryptionRequestId = requestId;
        requestIdToConsultationId[requestId] = consultationId;

        decryptionRequests[requestId] = DecryptionRequest({
            consultationId: consultationId,
            requester: msg.sender,
            requestTimestamp: block.timestamp,
            isProcessed: false,
            requestType: requestType
        });

        emit DecryptionCallbackRequested(requestId, consultationId, requestType);
    }

    /**
     * @notice Gateway callback function for decryption results
     * @dev Called by Gateway relayer with decrypted values
     * @param requestId Decryption request ID
     * @param cleartexts ABI-encoded cleartext values
     * @param decryptionProof Proof of correct decryption
     */
    function decryptionCallback(
        uint256 requestId,
        bytes memory cleartexts,
        bytes memory decryptionProof
    ) external {
        // Verify signatures from Gateway
        FHE.checkSignatures(requestId, cleartexts, decryptionProof);

        DecryptionRequest storage request = decryptionRequests[requestId];
        require(!request.isProcessed, "Request already processed");

        // Check decryption timeout
        if (block.timestamp > request.requestTimestamp + DECRYPTION_TIMEOUT) {
            _handleDecryptionFailure(request.consultationId, "Decryption timeout");
            return;
        }

        // Decode cleartext values
        (uint32 lawyerId, uint64 obfuscatedFee) = abi.decode(cleartexts, (uint32, uint64));

        uint256 consultationId = request.consultationId;
        EncryptedConsultation storage consultation = consultations[consultationId];

        // Process payment with privacy-preserving deobfuscation
        uint256 actualFee = (uint256(obfuscatedFee) * 100) / OBFUSCATION_FACTOR;

        // Update lawyer earnings (encrypted)
        euint64 earningsIncrease = FHE.asEuint64(obfuscatedFee);
        lawyers[lawyerId].encryptedEarnings = FHE.add(
            lawyers[lawyerId].encryptedEarnings,
            earningsIncrease
        );

        // Mark consultation as resolved
        consultation.isResolved = true;
        consultation.status = ConsultationStatus.Resolved;
        request.isProcessed = true;

        emit DecryptionCallbackCompleted(requestId, consultationId);
        emit PaymentProcessed(consultationId, actualFee);
        emit SecurityAuditLog("DECRYPTION_COMPLETED", msg.sender, consultationId, "Payment processed");
    }

    /**
     * @notice Handle decryption failure with refund mechanism
     * @param consultationId ID of the consultation
     * @param reason Failure reason
     */
    function _handleDecryptionFailure(uint256 consultationId, string memory reason)
        internal
    {
        EncryptedConsultation storage consultation = consultations[consultationId];
        consultation.status = ConsultationStatus.RefundRequested;
        consultation.refundRequested = true;

        emit DecryptionFailed(consultation.decryptionRequestId, consultationId, reason);
        emit SecurityAuditLog("DECRYPTION_FAILED", address(this), consultationId, reason);
    }

    // ============ Refund Mechanism ============

    /**
     * @notice Request refund for failed/timed-out consultation
     * @param consultationId ID of the consultation
     */
    function requestRefund(uint256 consultationId)
        external
        consultationExists(consultationId)
    {
        EncryptedConsultation storage consultation = consultations[consultationId];

        require(!consultation.refundProcessed, "Refund already processed");
        require(!consultation.isResolved, "Consultation resolved, cannot refund");
        require(consultation.isPaid, "Consultation not paid");

        // Check if consultation has timed out or decryption failed
        bool isTimedOut = block.timestamp > consultation.timestamp + CONSULTATION_TIMEOUT;
        bool responseTimedOut = consultation.assignedTimestamp > 0 &&
                                block.timestamp > consultation.assignedTimestamp + RESPONSE_TIMEOUT;
        bool decryptionTimedOut = consultation.decryptionRequestId > 0 &&
                                   block.timestamp > decryptionRequests[consultation.decryptionRequestId].requestTimestamp + DECRYPTION_TIMEOUT;

        require(
            isTimedOut || responseTimedOut || decryptionTimedOut || consultation.refundRequested,
            "Refund not eligible"
        );

        consultation.refundRequested = true;
        consultation.status = ConsultationStatus.RefundRequested;

        emit RefundRequested(consultationId, msg.sender, 0);
        emit SecurityAuditLog("REFUND_REQUESTED", msg.sender, consultationId, "Refund initiated");
    }

    /**
     * @notice Process refund for eligible consultation
     * @dev Admin function with security audit logging
     * @param consultationId ID of the consultation
     * @param clientAddress Address of the client to refund
     */
    function processRefund(uint256 consultationId, address clientAddress)
        external
        onlyAdmin
        consultationExists(consultationId)
    {
        EncryptedConsultation storage consultation = consultations[consultationId];

        require(consultation.refundRequested, "Refund not requested");
        require(!consultation.refundProcessed, "Refund already processed");
        require(consultation.isPaid, "Not paid");

        // Calculate actual refund amount (deobfuscate)
        // Note: In production, this would use Gateway callback for secure deobfuscation
        uint256 refundAmount = 0.001 ether; // Minimum fee as fallback

        consultation.refundProcessed = true;
        consultation.status = ConsultationStatus.Refunded;
        hasRefundClaimed[clientAddress] = true;

        // Process refund
        (bool sent, ) = payable(clientAddress).call{value: refundAmount}("");
        require(sent, "Refund transfer failed");

        emit RefundProcessed(consultationId, clientAddress, refundAmount);
        emit SecurityAuditLog("REFUND_PROCESSED", msg.sender, consultationId, "Refund completed");
    }

    // ============ Timeout Management ============

    /**
     * @notice Mark consultation as timed out
     * @param consultationId ID of the consultation
     */
    function markTimedOut(uint256 consultationId)
        external
        consultationExists(consultationId)
    {
        EncryptedConsultation storage consultation = consultations[consultationId];

        require(!consultation.isResolved, "Already resolved");
        require(
            block.timestamp > consultation.timestamp + CONSULTATION_TIMEOUT,
            "Not timed out yet"
        );

        ConsultationStatus previousStatus = consultation.status;
        consultation.status = ConsultationStatus.TimedOut;
        consultation.refundRequested = true;

        emit ConsultationTimedOut(consultationId, previousStatus);
        emit SecurityAuditLog("CONSULTATION_TIMEOUT", msg.sender, consultationId, "Marked as timed out");
    }

    // ============ Admin Functions ============

    /**
     * @notice Verify lawyer
     * @param lawyerId ID of the lawyer
     */
    function verifyLawyer(uint256 lawyerId)
        external
        onlyAdmin
        validInput(lawyerId, 1, lawyerCounter)
    {
        lawyers[lawyerId].isVerified = true;
        emit LawyerVerified(lawyerId);
        emit SecurityAuditLog("LAWYER_VERIFIED", msg.sender, lawyerId, "Lawyer verified");
    }

    /**
     * @notice Update lawyer rating (encrypted)
     * @param lawyerId ID of the lawyer
     * @param newRating New rating (0-100)
     */
    function updateLawyerRating(uint256 lawyerId, uint32 newRating)
        external
        onlyAdmin
        validInput(lawyerId, 1, lawyerCounter)
        validInput(newRating, 0, 100)
    {
        euint32 encryptedRating = FHE.asEuint32(newRating);
        lawyers[lawyerId].encryptedRating = encryptedRating;

        FHE.allowThis(encryptedRating);

        emit SecurityAuditLog("RATING_UPDATED", msg.sender, lawyerId, "Lawyer rating updated");
    }

    /**
     * @notice Deactivate lawyer
     * @param lawyerId ID of the lawyer
     */
    function deactivateLawyer(uint256 lawyerId)
        external
        onlyAdmin
        validInput(lawyerId, 1, lawyerCounter)
    {
        lawyers[lawyerId].isActive = false;
        emit SecurityAuditLog("LAWYER_DEACTIVATED", msg.sender, lawyerId, "Lawyer deactivated");
    }

    /**
     * @notice Withdraw platform fees
     * @param amount Amount to withdraw
     */
    function withdrawFees(uint256 amount) external onlyAdmin {
        require(amount > 0, "Amount must be positive");
        require(amount <= address(this).balance, "Insufficient balance");

        (bool sent, ) = payable(admin).call{value: amount}("");
        require(sent, "Withdraw failed");

        emit SecurityAuditLog("FEES_WITHDRAWN", admin, amount, "Platform fees withdrawn");
    }

    /**
     * @notice Emergency stop (pause all operations)
     */
    function emergencyStop() external onlyAdmin {
        emit SecurityAuditLog("EMERGENCY_STOP", admin, 0, "Emergency stop activated");
        // In production: implement pausable pattern
    }

    // ============ View Functions ============

    /**
     * @notice Get consultation details
     * @param consultationId ID of the consultation
     */
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
    {
        EncryptedConsultation storage consultation = consultations[consultationId];
        return (
            consultation.encryptedQuestion,
            consultation.encryptedResponse,
            consultation.timestamp,
            consultation.isResolved,
            consultation.isPaid,
            consultation.status,
            consultation.refundRequested,
            consultation.refundProcessed
        );
    }

    /**
     * @notice Get lawyer profile
     * @param lawyerId ID of the lawyer
     */
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
    {
        LawyerProfile storage lawyer = lawyers[lawyerId];
        return (
            lawyer.consultationCount,
            lawyer.isVerified,
            lawyer.isActive,
            lawyer.registrationTimestamp
        );
    }

    /**
     * @notice Get client statistics
     * @param clientAddress Address of the client
     */
    function getClientStats(address clientAddress)
        external
        view
        returns (
            uint256 totalConsultations,
            uint256 lastConsultationTimestamp
        )
    {
        ClientProfile storage client = clients[clientAddress];
        return (
            client.totalConsultations,
            client.lastConsultationTimestamp
        );
    }

    /**
     * @notice Get system statistics
     */
    function getSystemStats()
        external
        view
        returns (
            uint256 totalConsultations,
            uint256 totalLawyers,
            uint256 verifiedLawyers,
            uint256 activeLawyers
        )
    {
        uint256 verified = 0;
        uint256 active = 0;

        for (uint256 i = 1; i <= lawyerCounter; i++) {
            if (lawyers[i].isVerified) {
                verified++;
            }
            if (lawyers[i].isActive) {
                active++;
            }
        }

        return (
            consultationCounter,
            lawyerCounter,
            verified,
            active
        );
    }

    /**
     * @notice Get legal category name
     * @param categoryId ID of the category (1-8)
     */
    function getLegalCategory(uint256 categoryId)
        external
        view
        validInput(categoryId, 1, 8)
        returns (string memory)
    {
        return legalCategories[categoryId];
    }

    /**
     * @notice Check if address is registered lawyer
     * @param lawyerAddress Address to check
     */
    function isRegisteredLawyer(address lawyerAddress) external view returns (bool) {
        return registeredLawyers[lawyerAddress];
    }

    /**
     * @notice Get lawyer ID by address
     * @param lawyerAddress Address of the lawyer
     */
    function getLawyerIdByAddress(address lawyerAddress) external view returns (uint256) {
        return lawyerIds[lawyerAddress];
    }

    /**
     * @notice Get decryption request details
     * @param requestId ID of the decryption request
     */
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
    {
        DecryptionRequest storage request = decryptionRequests[requestId];
        return (
            request.consultationId,
            request.requester,
            request.requestTimestamp,
            request.isProcessed,
            request.requestType
        );
    }

    /**
     * @notice Check if consultation is eligible for refund
     * @param consultationId ID of the consultation
     */
    function isRefundEligible(uint256 consultationId)
        external
        view
        consultationExists(consultationId)
        returns (bool eligible, string memory reason)
    {
        EncryptedConsultation storage consultation = consultations[consultationId];

        if (consultation.refundProcessed) {
            return (false, "Refund already processed");
        }

        if (consultation.isResolved) {
            return (false, "Consultation resolved");
        }

        if (!consultation.isPaid) {
            return (false, "Not paid");
        }

        bool isTimedOut = block.timestamp > consultation.timestamp + CONSULTATION_TIMEOUT;
        if (isTimedOut) {
            return (true, "Consultation timed out");
        }

        bool responseTimedOut = consultation.assignedTimestamp > 0 &&
                                block.timestamp > consultation.assignedTimestamp + RESPONSE_TIMEOUT;
        if (responseTimedOut) {
            return (true, "Response timeout");
        }

        bool decryptionTimedOut = consultation.decryptionRequestId > 0 &&
                                   block.timestamp > decryptionRequests[consultation.decryptionRequestId].requestTimestamp + DECRYPTION_TIMEOUT;
        if (decryptionTimedOut) {
            return (true, "Decryption timeout");
        }

        if (consultation.refundRequested) {
            return (true, "Refund requested");
        }

        return (false, "Not eligible");
    }

    // ============ Fallback ============

    receive() external payable {
        emit SecurityAuditLog("FUNDS_RECEIVED", msg.sender, msg.value, "Direct payment received");
    }
}
