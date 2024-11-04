// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./CapybaraToken.sol";
import "./CapybaraNFTGate.sol";

/**
 * @title CapybaraDispenser
 * @dev Manages family rewards and exchanges in the Capybara system.
 */
contract CapybaraDispenser {

    // CAPYBARA token (global for all families)
    CapybaraToken public capybaraToken;

    //100 $CAPYBARA per 1 stablecoin
    uint256 effectiveRate = 100; 

    // Gate NFT contract (global for all families)
    CapybaraNFTGate public gateNFTContract;

    // External service URL that interacts with IPFS via a proxy server
    string public externalServiceBaseURI;

    // Family administrators wallets (adults)
    mapping(bytes32 => address[]) public familyAdmins;

    // Family children wallets (who earn CAPYBARA)
    mapping(bytes32 => address[]) public familyChildren;

    // Mapping to store which family an adult belongs to
    mapping(address => bytes32) public adultToFamily;

    // Mapping to store which family a child belongs to
    mapping(address => bytes32) public childToFamily;

    // Mapping of stablecoins for each family (family-specific)
    mapping(bytes32 => IERC20) public familyStablecoin;

    // Mapping from Gate NFT to FamilyIdentifier
    mapping(uint256 => bytes32) public gateNFTtoFamilyIdentifier;

    // Liquidity mapping for each family (family-specific)
    mapping(bytes32 => uint256) public familyLiquidity;

    // Activity index for each family (family-specific)
    mapping(bytes32 => uint256) public familyActivityIndex;

    // Daily limit on CAPYBARA exchange for each family (family-specific)
    mapping(bytes32 => uint256) public dailyCapybaraLimit;

    // Current CAPYBARA to DOGE exchange rate (global for all families)
    uint256 public capybaraToDogeRate;

    // Global activity index (global for all families)
    uint256 public globalActivityIndex;

    // $DOGE wallet address mapping for each family for rewards
    mapping(bytes32 => address) public familyDogeAddress;

    // Global Indicators
    
    // Total volume of CAPYBARA tokens exchanged between families (internal transactions)
    uint256 public totalInternalTransactionVolume;

    // Total count of CAPYBARA transactions between different families (internal transactions)
    uint256 public totalInternalTransactionCount;

    // Mapping to track total incoming liquidity per stablecoin (for all families)
    mapping(address => uint256) public totalIncomingLiquidity;

    // Mapping to track total outgoing liquidity per stablecoin (for all families)
    mapping(address => uint256) public totalOutgoingLiquidity;

    // Mapping that tracks the total liquidity distributed across different stablecoins in the entire system.
    // This reflects the total amount of liquidity held in each stablecoin across all families.
    mapping(address => uint256) public stablecoinsDistribution;


    // Events
    event MetadataFetched(string metadataJSON);
    event FamilySettingsUpdated(bytes32 familyId);
    event CapybaraExchanged(bytes32 familyId, address child, uint256 capybaraAmount, uint256 stablecoinAmount);
    event LiquidityDeposited(bytes32 familyId, address administrator, uint256 amount);
    event ChildActivityUpdated(bytes32 familyId, address child, uint256 amount);
    event DogeRewardsDistributed(bytes32 familyId, uint256 rewardAmount);

    /**
     * @dev Constructor to initialize the external service URI and CAPYBARA token.
     * @param _capybaraToken The address of the CAPYBARA token contract.
     * @param _gateNFTContract The address of the Gate NFT contract.
     * @param _externalServiceBaseURI The base URI of the external service that interacts with IPFS.
     */
    constructor(
        address _capybaraToken,
        address _gateNFTContract,
        string memory _externalServiceBaseURI
    ) {
        require(_capybaraToken != address(0), "Invalid token address");
        require(_gateNFTContract != address(0), "Invalid NFT contract address");
        capybaraToken = CapybaraToken(_capybaraToken);
        gateNFTContract = CapybaraNFTGate(_gateNFTContract);
        externalServiceBaseURI = _externalServiceBaseURI;
    }

    /**
    * @dev Checks if the given address is an adult in any family.
    * @param userAddress The address to check.
    * @return bool Returns true if the address is an adult.
    */
    function isAdult(address userAddress) public view returns (bool) {
        // Check if the address exists in the adultToFamily mapping
        return adultToFamily[userAddress] != bytes32(0);
    }

    /**
    * @dev Checks if the given address is a child in any family.
    * @param userAddress The address to check.
    * @return bool Returns true if the address is a child.
    */
    function isChild(address userAddress) public view returns (bool) {
        // Check if the address exists in the childToFamily mapping
        return childToFamily[userAddress] != bytes32(0);
    }

    /**
     * @dev Fetches metadata from an external service (via proxy to IPFS).
     * @param metadataURI The metadata URI (CID) stored in the Gate NFT.
     * @return metadataJSON The fetched metadata in JSON format.
     */
    function _fetchMetadataFromURI(string memory metadataURI) internal returns (string memory) {
        string memory fullURL = string(abi.encodePacked(externalServiceBaseURI, "/retrieve/", metadataURI));
        emit MetadataFetched(fullURL);
        return ""; // Assume fetched off-chain
    }
    
    /**
     * @dev Track family settings and emit an event to fetch metadata off-chain.
     * @param gateNFTId The ID of the Gate NFT.
     */
    function trackFamilySettings(uint256 gateNFTId) external {
        //string memory metadataURI = _getMetadataURI(gateNFTId); // Получаем метаданные URI с Gate NFT
        //emit MetadataFetched(gateNFTId, metadataURI); // Выпускаем событие, которое ловит Web2
    }

    /**
    * @dev Update family settings after fetching metadata (called via Web2).
    * @param gateNFTId The ID of the Gate NFT.
    * @param stablecoin The stablecoin address for the family.
    * @param liquidity The liquidity available for the family.
    * @param dailyLimit The daily CAPYBARA token limit for the family.
    * @param admins Array of administrators for the family.
    * @param children Array of children addresses.
    * @param dogeAddress The DOGE address for rewards.
    */
    function updateFamilySettings(
        uint256 gateNFTId,
        address stablecoin,
        uint256 liquidity,
        uint256 dailyLimit,
        //uint256 capybaraTokens,
        address[] memory admins,
        address[] memory children,
        address dogeAddress
    ) external {
        bytes32 familyId = gateNFTtoFamilyIdentifier[gateNFTId];

        // Update family-specific settings
        familyStablecoin[familyId] = IERC20(stablecoin);
        familyLiquidity[familyId] = liquidity;
        dailyCapybaraLimit[familyId] = dailyLimit;
        familyDogeAddress[familyId] = dogeAddress;

        // We update administrators and children
        familyAdmins[familyId] = admins;
        familyChildren[familyId] = children;

        // Update admins and children in the family and assign them to the family
        for (uint256 i = 0; i < admins.length; i++) {
            adultToFamily[admins[i]] = familyId;
        }

        for (uint256 j = 0; j < children.length; j++) {
            childToFamily[children[j]] = familyId;
        }

        emit FamilySettingsUpdated(familyId);
    }


    /**
     * @dev Retrieves family settings from the metadata associated with a Gate NFT.
     * @param gateNFTId The ID of the Gate NFT.
     * @return stablecoin The stablecoin address for the family.
     * @return liquidity The available liquidity for the family.
     * @return dailyLimit The daily CAPYBARA token limit for the family.
     */
    function getFamilySettingsFromNFT(uint256 gateNFTId)
        external
        view
        returns (address stablecoin, uint256 liquidity, uint256 dailyLimit)
    {
        bytes32 familyId = gateNFTtoFamilyIdentifier[gateNFTId];
        return (
            address(familyStablecoin[familyId]),
            familyLiquidity[familyId],
            dailyCapybaraLimit[familyId]
        );
    }

    /**
    * @dev Defines the role of the user and returns the family identifier.
    * @param userAddress Address of the user (child or adult).
    * @return role 0 if a child, 1 if an adult.
    * @return familyId Идентификатор семьи.
    * @return stablecoin Stablecoin address for an adult (if the user is an adult).
    */
    function getRoleAndFamily(address userAddress) external view returns (uint8 role, bytes32 familyId, address stablecoin) {
        if (isChild(userAddress)) {
            return (0, childToFamily[userAddress], address(0)); // Role: Child, return family id
        } else if (isAdult(userAddress)) {
            return (1, adultToFamily[userAddress], address(familyStablecoin[adultToFamily[userAddress]])); // Role: Adult, return family ID and stablecoin address
        } else {
            revert("Address not recognized");
        }
    }

    /**
     * @dev Handles exchange of CAPYBARA tokens for stablecoins.
     * @param amount The amount of CAPYBARA tokens to exchange.
     */
    function exchangeCapybara(uint256 amount, bytes32 familyId) external {
        require(amount <= dailyCapybaraLimit[familyId], "Exceeds daily limit");

        //uint256 penaltyRate = familyPenalties[familyId].penaltyRate;
        uint256 stablecoinAmount = (amount / effectiveRate);

        require(familyLiquidity[familyId] >= stablecoinAmount, "Insufficient liquidity");

        capybaraToken.transferFrom(msg.sender, address(this), amount);
        familyStablecoin[familyId].transfer(msg.sender, stablecoinAmount);
        familyLiquidity[familyId] -= stablecoinAmount;

        emit CapybaraExchanged(familyId, msg.sender, amount, stablecoinAmount);
    }

    /**
    * @dev Updates the family's liquidity with stablecoins.
    * @param amount The amount of stablecoins to send to liquidity.
    * @param familyId Family Identifier
    */
    function depositLiquidity(uint256 amount, bytes32 familyId, address stablecoinAddress) external {
        require(isAdult(msg.sender), "Only adults can deposit liquidity");
        require(address(familyStablecoin[familyId]) == stablecoinAddress, "Invalid stablecoin for this family");

        IERC20 stablecoin = IERC20(stablecoinAddress);
        
        // Transferring stablecoins from the sender's address to the contract
        stablecoin.transferFrom(msg.sender, address(this), amount);
        
        // Updating the family's liquidity
        familyLiquidity[familyId] += amount;

        emit LiquidityDeposited(familyId, msg.sender, amount);
    }

    /**
     * @dev Updates a child's activity and family activity index.
     * @param gateNFTId The ID of the Gate NFT linked to the family.
     * @param amount The amount of activity to add.
     */
    function updateChildActivity(uint256 gateNFTId, uint256 amount) external {
        bytes32 familyId = gateNFTtoFamilyIdentifier[gateNFTId];
        familyActivityIndex[familyId] += amount;
        globalActivityIndex += amount;

        emit ChildActivityUpdated(familyId, msg.sender, amount);
    }

    /**
     * @dev Distributes DOGE rewards based on family activity index.
     * @param gateNFTId The ID of the Gate NFT linked to the family.
     */
    function distributeDogeRewards(uint256 gateNFTId) external {
        //bytes32 familyId = gateNFTtoFamilyIdentifier[gateNFTId];
        //uint256 rewardAmount = calculateRewards(familyId);
        // Assume dogeToken logic for DOGE transfers
        //emit DogeRewardsDistributed(familyId, rewardAmount);
    }

    /**
     * @dev Calculates the current exchange rate of CAPYBARA to DOGE.
     * @return The current exchange rate based on the system's global activity index.
     */
    function getExchangeRateCapybaraToDoge() external view returns (uint256) {
        return capybaraToDogeRate;
    }

    /**
     * @dev Internal function to get metadata URI from Gate NFT.
     * @param gateNFTId The ID of the Gate NFT.
     * @return metadataURI The metadata URI.
     */
    //function _getMetadataURI(uint256 gateNFTId) internal view returns (string memory) {
      // return ""; //return gateNFTContract.tokenURI(gateNFTId);
    //}

    /**
     * @dev Updates the external service base URI.
     * @param _newBaseURI The new base URI for the external service.
     */
    function updateExternalServiceBaseURI(string memory _newBaseURI) external {
        externalServiceBaseURI = _newBaseURI;
    }
}
