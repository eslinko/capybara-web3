// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CapybaraNFTGate is ERC721URIStorage, Ownable {

    // Counter for NFT IDs
    uint256 private nextTokenId;

    // Mapping for storing token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Event to emit when a new Gate NFT is minted
    event GateNFTMinted(address to, uint256 tokenId, string tokenURI);

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) Ownable(msg.sender) {
        nextTokenId = 1;  // Start token IDs from 1
    }

    /**
     * @notice Function to mint a new Gate NFT and set the metadata URI.
     * @param to The address that will receive the newly minted NFT.
     * @param metadataCID The IPFS CID (Content Identifier) that points to the metadata.
     */
    function mintGateNFT(address to, string memory metadataCID) public onlyOwner {
        uint256 tokenId = nextTokenId;

        // Mint the NFT to the specified address
        _mint(to, tokenId);

        // Create the full IPFS URI and set it as the token's metadata URI
        _setTokenURI(tokenId, string(abi.encodePacked("ipfs://", metadataCID)));

        // Emit event when NFT is minted
        emit GateNFTMinted(to, tokenId, string(abi.encodePacked("ipfs://", metadataCID)));

        // Increment the token ID counter for the next minting
        nextTokenId++;
    }

    /**
    * @notice Internal function to set the token URI for a specific token ID.
    * @param tokenId The ID of the token.
    * @param uri The URI of the token metadata (usually an IPFS link).
    */
    function _setTokenURI(uint256 tokenId, string memory uri) internal override {
        super._setTokenURI(tokenId, uri);
    }

    /**
    * @notice Public function to get the token URI for a specific token ID.
    * @param tokenId The ID of the token.
    * @return The URI of the token metadata.
    */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return super.tokenURI(tokenId); // Обязательно нужно возвращать значение
    }

}
