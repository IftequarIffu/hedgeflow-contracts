// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;


contract CreditDefaultSwap {
    
    struct CDSSeller {
        address seller;              // Seller of the CDS contract
        uint256 coverageAmount;      // Amount in Ether covered by CDS
        uint256 premiumPercentage;   // Premium percentage (10% or 20%)
        uint256 tenureMonths;        // Contract tenure in months
    }

    struct BuyerContract {
        address buyer;
        uint256 premiumAmount;
        uint256 monthlyPremiumDueDate;
        uint256 missedPayments;
        bool isActive;
        bool isDefaulted;
    }

    // Seller information
    mapping(address => CDSSeller) public cdsSellers;
    // Each seller has a list of buyer contracts
    mapping(address => mapping(address => BuyerContract)) public buyerContracts;
    mapping(address => address[]) public sellerBuyers; // Stores buyers of a specific seller

    uint256 public constant gracePeriodDays = 7;     // Grace period for premium payment
    uint256 public constant maxMissedPayments = 3;   // Max consecutive missed payments

    event ContractRegistered(address indexed seller, uint256 coverageAmount, uint256 premiumPercentage);
    event PremiumPaid(address indexed buyer, address indexed seller, uint256 amount);
    event ContractDefaulted(address indexed buyer, address indexed seller);
    event ContractTerminated(address indexed buyer, address indexed seller);
    event ContractSold(address indexed seller, uint256 coverageAmount);

    // Register seller with a new CDS contract
    function registerSellerOnPlatform(
        uint256 _coverageAmount,
        uint256 _premiumPercentage,
        uint256 _tenureMonths
    ) public {
        require(_premiumPercentage == 10 || _premiumPercentage == 20, "Premium must be 10% or 20%");
        
        cdsSellers[msg.sender] = CDSSeller({
            seller: msg.sender,
            coverageAmount: _coverageAmount,
            premiumPercentage: _premiumPercentage,
            tenureMonths: _tenureMonths
        });

        emit ContractRegistered(msg.sender, _coverageAmount, _premiumPercentage);
    }

    // Allow seller to lock coverage amount in the contract
    function sellCDS() public payable {
        CDSSeller storage sellerData = cdsSellers[msg.sender];
        require(msg.value == sellerData.coverageAmount, "Incorrect coverage amount");
        
        emit ContractSold(msg.sender, msg.value);
    }


    // Buyer initiates a CDS contract with the seller
    function buyCDS(address _seller) public {
        CDSSeller storage sellerData = cdsSellers[_seller];
        require(sellerData.seller != address(0), "Seller not registered");
        
        uint256 monthlyPremium = (sellerData.coverageAmount * sellerData.premiumPercentage) / (100 * sellerData.tenureMonths);
        
        buyerContracts[_seller][msg.sender] = BuyerContract({
            buyer: msg.sender,
            premiumAmount: monthlyPremium,
            monthlyPremiumDueDate: block.timestamp + 30 days,
            missedPayments: 0,
            isActive: true,
            isDefaulted: false
        });

        sellerBuyers[_seller].push(msg.sender); // Track each buyer for the seller
    }


}