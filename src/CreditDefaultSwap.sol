// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;


contract CreditDefaultSwap {
    
    struct CDSSeller {
        address seller;              // Seller of the CDS contract
        uint256 coverageAmount;      // Amount in Ether covered by CDS
        uint256 premiumPercentage;   // Premium percentage (10% or 20%)
        uint256 tenureMonths;        // Contract tenure in months
    }

    struct CDSContract {
        address buyer;
        address seller;
        uint256 coverageAmount;
        uint256 premiumAmount;
        uint256 monthlyPremiumDueDate;
        uint256 missedPayments;
        bool isActive;
        bool isDefaulted;
    }

    mapping(address => CDSContract) public cdsContracts;
    uint256 public constant gracePeriodDays = 7;     // Grace period for premium payment
    uint256 public constant maxMissedPayments = 3;   // Max consecutive missed payments

    event ContractRegistered(address indexed seller, uint256 coverageAmount, uint256 premiumPercentage);
    event PremiumPaid(address indexed buyer, address indexed seller, uint256 amount);
    event ContractDefaulted(address indexed buyer, address indexed seller);
    event ContractTerminated(address indexed buyer, address indexed seller);
    event ContractSold(address indexed seller, uint256 coverageAmount);

    


}