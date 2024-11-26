// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title HYBLOCK Token
 * @dev Implementation of the HYBLOCK token.
 */
contract HYBLOCKToken is ERC20, ERC20Burnable, Ownable, Pausable {
    // Token details
    string private constant TOKEN_NAME = "HYBLOCK";
    string private constant TOKEN_SYMBOL = "HYB";
    uint8 private constant TOKEN_DECIMALS = 18;
    uint256 private constant INITIAL_SUPPLY = 1_000_000_000; // 1 billion tokens

    // Events
    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);

    constructor() ERC20(TOKEN_NAME, TOKEN_SYMBOL) Ownable(msg.sender) {
        _mint(msg.sender, INITIAL_SUPPLY * (10 ** decimals()));
    }

    /**
     * @dev Mints new tokens. Only callable by owner.
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    /**
     * @dev Burns tokens from the caller's account
     * @param amount Amount of tokens to burn
     */
    function burn(uint256 amount) public override {
        super.burn(amount);
        emit TokensBurned(_msgSender(), amount);
    }

    /**
     * @dev Pause token transfers. Only callable by owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause token transfers. Only callable by owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Hook that is called before any transfer of tokens.
     */
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) whenNotPaused {
        super._update(from, to, amount);
    }

    /**
     * @dev Returns the number of decimals used for token amounts.
     */
    function decimals() public pure override returns (uint8) {
        return TOKEN_DECIMALS;
    }
}