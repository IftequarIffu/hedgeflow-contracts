// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;


contract CreditDefaultSwap {
    
    struct CDSSeller {
        string sellerName;
        string contractName;
        address sellerAddress;              // Seller of the CDS contract
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

    address[] public sellers;
    address[] public buyers;

    // Seller information
    mapping(address => CDSSeller) public cdsSellerDetails;
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
        string memory _sellerName,
        string memory _contractName,
        uint256 _coverageAmount,
        uint256 _premiumPercentage,
        uint256 _tenureMonths
    ) public {
        require(_premiumPercentage == 10 || _premiumPercentage == 20, "Premium must be 10% or 20%");
        
        cdsSellerDetails[msg.sender] = CDSSeller({
            sellerName: _sellerName,
            contractName: _contractName,
            sellerAddress: msg.sender,
            coverageAmount: _coverageAmount,
            premiumPercentage: _premiumPercentage,
            tenureMonths: _tenureMonths
        });

        sellers.push(payable(msg.sender));

        emit ContractRegistered(msg.sender, _coverageAmount, _premiumPercentage);
    }

    function getAllSellerAddresses() public view returns(address[] memory) {
        return sellers;
    }

    function getSellerDetailsFromAddress(address sellerAddress) public view returns(CDSSeller memory) {
        require(sellerAddress != address(0), "Input address is a Zero Address");
        return cdsSellerDetails[sellerAddress];
    }

    // Allow seller to lock coverage amount in the contract
    function sellCDS() public payable {
        CDSSeller storage sellerData = cdsSellerDetails[msg.sender];
        require(msg.value == sellerData.coverageAmount, "Incorrect coverage amount");
        
        emit ContractSold(msg.sender, msg.value);
    }


    // Buyer initiates a CDS contract with the seller
    function buyCDS(address _seller) public {
        CDSSeller storage sellerData = cdsSellerDetails[_seller];
        require(sellerData.sellerAddress != address(0), "Seller not registered");
        
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

    // Buyer makes a monthly premium payment
    function payPremium(address _seller) public payable {
        BuyerContract storage buyerData = buyerContracts[_seller][msg.sender];
        require(buyerData.isActive, "Contract not active");
        require(!buyerData.isDefaulted, "Contract in default");

        uint256 currentTimestamp = block.timestamp;

        // Check if the payment is within grace period
        if (currentTimestamp > buyerData.monthlyPremiumDueDate + gracePeriodDays * 1 days) {
            buyerData.missedPayments += 1;
        } else {
            buyerData.missedPayments = 0; // Reset missed payments if paid on time
        }

        // Check for contract default
        if (buyerData.missedPayments >= maxMissedPayments) {
            buyerData.isActive = false;
            buyerData.isDefaulted = true;
            // Release seller's coverage amount in proportion to this buyer's premium
            payable(_seller).transfer(buyerData.premiumAmount * cdsSellerDetails[_seller].tenureMonths);
            emit ContractDefaulted(buyerData.buyer, _seller);
        } else {
            // Process premium payment
            require(msg.value == buyerData.premiumAmount, "Incorrect premium amount");
            payable(_seller).transfer(msg.value);
            emit PremiumPaid(buyerData.buyer, _seller, msg.value);

            // Update next due date
            buyerData.monthlyPremiumDueDate += 30 days;
        }
    }

    // Terminate the contract for a specific buyer
    function terminateContract(address _seller) public {
        BuyerContract storage buyerData = buyerContracts[_seller][msg.sender];
        require(buyerData.isActive, "Contract already terminated");
        
        buyerData.isActive = false;
        emit ContractTerminated(msg.sender, _seller);
    }
}