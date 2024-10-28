// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PropertyLeasing {
    address public owner;
    address public tenant;
    uint256 public rentAmount;
    uint256 public securityDeposit;
    uint256 public leaseDuration;
    uint256 public paymentFrequency;
    uint256 public leaseStart;
    uint256 public lastPaymentDate;
    bool public isActive;

    uint256 public lateFeePercentage = 5;

    // Events
    event LeaseStarted(address tenant, uint256 leaseStart);
    event RentPaid(address tenant, uint256 amount, uint256 date);
    event LeaseTerminated(address tenant, uint256 terminationDate);
    event LateFeeCharged(address tenant, uint256 lateFee, uint256 date);

    // modifiers
    modifier onlyOwner() {
        require(msg.sender != address(0), "Zero address not allowed");
        require(msg.sender == owner, "Not allowed");
        _;
    }

    modifier onlyTenant() {
        require(
            msg.sender == tenant,
            "Only the tenant can perform this action"
        );
        _;
    }

    modifier leaseIsActive() {
        require(isActive, "The lease is not active");
        _;
    }

    constructor(
        uint256 _rentAmount,
        uint256 _securityDeposit,
        uint256 _leaseDuration,
        uint256 _paymentFrequency
    ) {
        owner = msg.sender;
        rentAmount = _rentAmount;
        securityDeposit = _securityDeposit;
        leaseDuration = _leaseDuration;
        paymentFrequency = _paymentFrequency;
        isActive = false;
    }

    function startLease() external payable {
        require(msg.sender != address(0), "Zero address not allowed");
        require(!isActive, "Lease is already active");
        require(
            msg.value == rentAmount + securityDeposit,
            "Incorrect initial payment"
        );

        tenant = msg.sender;
        leaseStart = block.timestamp;
        lastPaymentDate = block.timestamp;
        isActive = true;

        emit LeaseStarted(tenant, leaseStart);
    }

    function payRent() external payable onlyTenant leaseIsActive {
        require(msg.sender != address(0), "Zero address not allowed");
        require(msg.value == rentAmount, "Incorrect rent amount");
        require(
            block.timestamp >= lastPaymentDate + paymentFrequency,
            "Payment too early"
        );

        if (block.timestamp > lastPaymentDate + paymentFrequency) {
            uint256 lateFee = (rentAmount * lateFeePercentage) / 100;
            require(
                msg.value == rentAmount + lateFee,
                "Incorrect payment with late fee"
            );
            emit LateFeeCharged(tenant, lateFee, block.timestamp);
        }

        lastPaymentDate = block.timestamp;
        payable(owner).transfer(rentAmount);

        emit RentPaid(tenant, rentAmount, block.timestamp);
    }

    function endLease() external onlyTenant leaseIsActive {
        require(msg.sender != address(0), "Zero address not allowed");
        require(
            block.timestamp >= leaseStart + leaseDuration,
            "Lease duration has not ended yet"
        );

        isActive = false;
        payable(tenant).transfer(securityDeposit);

        emit LeaseTerminated(tenant, block.timestamp);
    }

    function terminateLease() external onlyOwner leaseIsActive {
        isActive = false;
        tenant = address(0);
        payable(owner).transfer(address(this).balance);

        emit LeaseTerminated(tenant, block.timestamp);
    }

    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
