// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract CarRental is ReentrancyGuard {
    address public owner;
    address public renter;
    uint256 public rentalAmount;
    uint256 public securityDeposit;
    uint256 public rentalDuration;
    uint256 public paymentFrequency;
    uint256 public rentalStart;
    uint256 public lastPaymentDate;
    bool public isActive;

    uint256 public lateFeePercentage = 5;

    // Events
    event RentalStarted(address renter, uint256 rentalStart);
    event RentPaid(address renter, uint256 amount, uint256 date);
    event RentalTerminated(address renter, uint256 terminationDate);
    event LateFeeCharged(address renter, uint256 lateFee, uint256 date);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender != address(0), "Zero address not allowed");
        require(msg.sender == owner, "Not allowed");
        _;
    }

    modifier onlyRenter() {
        require(msg.sender != address(0), "Zero address not allowed");
        require(
            msg.sender == renter,
            "Only the renter can perform this action"
        );
        _;
    }

    modifier rentalIsActive() {
        require(msg.sender != address(0), "Zero address not allowed");
        require(isActive, "The rental is not active");
        _;
    }

    constructor(
        uint256 _rentalAmount,
        uint256 _securityDeposit,
        uint256 _rentalDuration,
        uint256 _paymentFrequency
    ) {
        owner = msg.sender;
        rentalAmount = _rentalAmount;
        securityDeposit = _securityDeposit;
        rentalDuration = _rentalDuration;
        paymentFrequency = _paymentFrequency;
        isActive = false;
    }

    function startRental() external payable {
        require(msg.sender != address(0), "Zero address not allowed");
        require(!isActive, "Rental is already active");
        require(
            msg.value == rentalAmount + securityDeposit,
            "Incorrect initial payment"
        );

        renter = msg.sender;
        rentalStart = block.timestamp;
        lastPaymentDate = block.timestamp;
        isActive = true;

        emit RentalStarted(renter, rentalStart);
    }

    function payRent() external payable onlyRenter rentalIsActive {
        require(msg.sender != address(0), "Zero address not allowed");
        require(msg.value == rentalAmount, "Incorrect rent amount");
        require(
            block.timestamp >= lastPaymentDate + paymentFrequency,
            "Payment too early"
        );

        if (block.timestamp > lastPaymentDate + paymentFrequency) {
            uint256 lateFee = (rentalAmount * lateFeePercentage) / 100;
            require(
                msg.value == rentalAmount + lateFee,
                "Incorrect payment with late fee"
            );
            emit LateFeeCharged(renter, lateFee, block.timestamp);
        }

        lastPaymentDate = block.timestamp;
        payable(owner).transfer(rentalAmount);

        emit RentPaid(renter, rentalAmount, block.timestamp);
    }

    function endRental() external onlyRenter rentalIsActive {
        require(msg.sender != address(0), "Zero address not allowed");
        require(
            block.timestamp >= rentalStart + rentalDuration,
            "Rental duration has not ended yet"
        );

        isActive = false;
        payable(renter).transfer(securityDeposit);

        emit RentalTerminated(renter, block.timestamp);
    }

    function terminateRental() external onlyOwner rentalIsActive {
        isActive = false;
        renter = address(0);
        payable(owner).transfer(address(this).balance);

        emit RentalTerminated(renter, block.timestamp);
    }

    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
