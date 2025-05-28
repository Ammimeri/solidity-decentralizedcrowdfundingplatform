// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Decentralized Crowdfunding Platform
 * @dev Smart contract for creating and managing crowdfunding campaigns
 */
contract Project {
    // Project structure
    struct Campaign {
        address payable creator;
        string title;
        string description;
        uint256 goal;
        uint256 deadline;
        uint256 amountRaised;
        bool goalReached;
        bool fundsWithdrawn;
        mapping(address => uint256) contributions;
        address[] contributors;
    }
    
    // State variables
    mapping(uint256 => Campaign) public campaigns;
    uint256 public campaignCount;
    
    // Events
    event CampaignCreated(
        uint256 indexed campaignId,
        address indexed creator,
        string title,
        uint256 goal,
        uint256 deadline
    );
    
    event ContributionMade(
        uint256 indexed campaignId,
        address indexed contributor,
        uint256 amount
    );
    
    event FundsWithdrawn(
        uint256 indexed campaignId,
        address indexed creator,
        uint256 amount
    );
    
    event RefundClaimed(
        uint256 indexed campaignId,
        address indexed contributor,
        uint256 amount
    );
    
    // Modifiers
    modifier campaignExists(uint256 _campaignId) {
        require(_campaignId < campaignCount, "Campaign does not exist");
        _;
    }
    
    modifier onlyCreator(uint256 _campaignId) {
        require(
            msg.sender == campaigns[_campaignId].creator,
            "Only campaign creator can call this function"
        );
        _;
    }
    
    modifier campaignActive(uint256 _campaignId) {
        require(
            block.timestamp < campaigns[_campaignId].deadline,
            "Campaign has ended"
        );
        _;
    }
    
    // Core Function 1: Create Campaign
    function createCampaign(
        string memory _title,
        string memory _description,
        uint256 _goal,
        uint256 _durationInDays
    ) external returns (uint256) {
        require(_goal > 0, "Goal must be greater than 0");
        require(_durationInDays > 0, "Duration must be greater than 0");
        require(bytes(_title).length > 0, "Title cannot be empty");
        
        uint256 campaignId = campaignCount;
        Campaign storage newCampaign = campaigns[campaignId];
        
        newCampaign.creator = payable(msg.sender);
        newCampaign.title = _title;
        newCampaign.description = _description;
        newCampaign.goal = _goal;
        newCampaign.deadline = block.timestamp + (_durationInDays * 1 days);
        newCampaign.amountRaised = 0;
        newCampaign.goalReached = false;
        newCampaign.fundsWithdrawn = false;
        
        campaignCount++;
        
        emit CampaignCreated(campaignId, msg.sender, _title, _goal, newCampaign.deadline);
        
        return campaignId;
    }
    
    // Core Function 2: Contribute to Campaign
    function contribute(uint256 _campaignId) 
        external 
        payable 
        campaignExists(_campaignId) 
        campaignActive(_campaignId) 
    {
        require(msg.value > 0, "Contribution must be greater than 0");
        
        Campaign storage campaign = campaigns[_campaignId];
        
        // If first time contributor, add to contributors array
        if (campaign.contributions[msg.sender] == 0) {
            campaign.contributors.push(msg.sender);
        }
        
        campaign.contributions[msg.sender] += msg.value;
        campaign.amountRaised += msg.value;
        
        // Check if goal is reached
        if (campaign.amountRaised >= campaign.goal) {
            campaign.goalReached = true;
        }
        
        emit ContributionMade(_campaignId, msg.sender, msg.value);
    }
    
    // Core Function 3: Withdraw Funds (for successful campaigns)
    function withdrawFunds(uint256 _campaignId) 
        external 
        campaignExists(_campaignId) 
        onlyCreator(_campaignId) 
    {
        Campaign storage campaign = campaigns[_campaignId];
        
        require(block.timestamp >= campaign.deadline, "Campaign is still active");
        require(campaign.goalReached, "Goal not reached");
        require(!campaign.fundsWithdrawn, "Funds already withdrawn");
        require(campaign.amountRaised > 0, "No funds to withdraw");
        
        campaign.fundsWithdrawn = true;
        uint256 amount = campaign.amountRaised;
        
        campaign.creator.transfer(amount);
        
        emit FundsWithdrawn(_campaignId, msg.sender, amount);
    }
    
    // Additional Function: Claim Refund (for failed campaigns)
    function claimRefund(uint256 _campaignId) 
        external 
        campaignExists(_campaignId) 
    {
        Campaign storage campaign = campaigns[_campaignId];
        
        require(block.timestamp >= campaign.deadline, "Campaign is still active");
        require(!campaign.goalReached, "Goal was reached, no refund available");
        require(campaign.contributions[msg.sender] > 0, "No contribution found");
        
        uint256 refundAmount = campaign.contributions[msg.sender];
        campaign.contributions[msg.sender] = 0;
        
        payable(msg.sender).transfer(refundAmount);
        
        emit RefundClaimed(_campaignId, msg.sender, refundAmount);
    }
    
    // View Functions
    function getCampaignDetails(uint256 _campaignId) 
        external 
        view 
        campaignExists(_campaignId) 
        returns (
            address creator,
            string memory title,
            string memory description,
            uint256 goal,
            uint256 deadline,
            uint256 amountRaised,
            bool goalReached,
            bool fundsWithdrawn
        ) 
    {
        Campaign storage campaign = campaigns[_campaignId];
        return (
            campaign.creator,
            campaign.title,
            campaign.description,
            campaign.goal,
            campaign.deadline,
            campaign.amountRaised,
            campaign.goalReached,
            campaign.fundsWithdrawn
        );
    }
    
    function getContribution(uint256 _campaignId, address _contributor) 
        external 
        view 
        campaignExists(_campaignId) 
        returns (uint256) 
    {
        return campaigns[_campaignId].contributions[_contributor];
    }
    
    function getContributorsCount(uint256 _campaignId) 
        external 
        view 
        campaignExists(_campaignId) 
        returns (uint256) 
    {
        return campaigns[_campaignId].contributors.length;
    }
    
    function isCampaignActive(uint256 _campaignId) 
        external 
        view 
        campaignExists(_campaignId) 
        returns (bool) 
    {



        return block.timestamp < campaigns[_campaignId].deadline;
    }
}
