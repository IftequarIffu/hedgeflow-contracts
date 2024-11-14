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

    function registerSellerOnPlatform(
        uint256 _coverageAmount,
        uint256 _premiumPercentage,
        uint256 _tenureMonths
    ) public {
        require(_premiumPercentage == 10 || _premiumPercentage == 20, "Premium must be 10% or 20%");
        
        uint256 monthlyPremium = (_coverageAmount * _premiumPercentage) / (100 * _tenureMonths);

        cdsContracts[msg.sender] = CDSContract({
            buyer: address(0),
            seller: msg.sender,
            coverageAmount: _coverageAmount,
            premiumAmount: monthlyPremium,
            monthlyPremiumDueDate: 0,
            missedPayments: 0,
            isActive: false,
            isDefaulted: false
        });

        emit ContractRegistered(msg.sender, _coverageAmount, _premiumPercentage);
    }

    function sellCDS() public payable {
        CDSContract storage contractData = cdsContracts[msg.sender];
        require(msg.value == contractData.coverageAmount, "Incorrect coverage amount");
        require(!contractData.isActive, "CDS contract already active");
        require(contractData.buyer == address(0), "CDS contract already has a buyer");

        // Lock the coverage amount in the smart contract's escrow
        contractData.coverageAmount = msg.value;

        emit ContractSold(msg.sender, msg.value);
    }


}