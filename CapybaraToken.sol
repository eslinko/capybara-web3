// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CapybaraToken
 * @dev ERC-20 token with minting functionalities.
 */
contract CapybaraToken is ERC20, Ownable {

    uint256 public constant INITIAL_SUPPLY = 100 * 10 ** 18;

    /**
     * @dev Contract constructor.
     * Mints the initial supply of tokens to the owner of the contract.
     * @param owner The address of the owner that will receive the initial supply.
     */
    constructor(address owner) ERC20("Capybara is a child money", "CAPYBARA") Ownable(owner) {
        require(owner != address(0), "Owner address cannot be zero");
        require(INITIAL_SUPPLY > 0, "Initial supply must be greater than zero");

        _transferOwnership(owner);
        _mint(owner, INITIAL_SUPPLY);
    }

}
