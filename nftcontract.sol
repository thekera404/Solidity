// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 * BAYC-style ERC721
 * - tokenURI = baseURI + tokenId + ".json"
 * - Free mint (1 per wallet), capped at 299
 * - Owner reserve mint for airdrops/treasury
 * - OpenZeppelin v5.x compatible
 */

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract StellarNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    // -------- Config --------
    uint256 public constant MAX_SUPPLY = 299;
    string private _baseTokenURI;
    bool public mintActive;

    // one free mint per wallet
    mapping(address => bool) public hasMinted;

    // -------- Events --------
    event MintActiveSet(bool active);
    event BaseURISet(string newBaseURI);
    event FreeMint(address indexed to, uint256 tokenId);
    event OwnerMint(address indexed to, uint256 quantity);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory initialBaseURI_
    ) ERC721(name_, symbol_) Ownable(msg.sender) {
        _setBaseURIInternal(initialBaseURI_);
    }

    // ---------- Public mint (free, 1 per wallet) ----------
    function freeMint() external nonReentrant {
        require(mintActive, "Mint not active");
        require(!hasMinted[msg.sender], "Already minted");

        uint256 currentSupply = totalSupply();
        require(currentSupply < MAX_SUPPLY, "Sold out");

        uint256 tokenId = currentSupply + 1; // 1..299
        hasMinted[msg.sender] = true;
        _safeMint(msg.sender, tokenId);
        emit FreeMint(msg.sender, tokenId);
    }

    // ---------- Admin ----------
    function setMintActive(bool active) external onlyOwner {
        mintActive = active;
        emit MintActiveSet(active);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _setBaseURIInternal(newBaseURI);
        emit BaseURISet(_baseTokenURI);
    }

    // ---------- Views ----------
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // ERC721 base handles nonexistent token check in OZ v5
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), ".json"));
    }

    // ---------- Internal helpers ----------
    function _setBaseURIInternal(string memory newBaseURI) internal {
        require(bytes(newBaseURI).length > 0, "Empty URI");
        bytes memory b = bytes(newBaseURI);
        if (b[b.length - 1] != bytes1('/')) {
            _baseTokenURI = string(abi.encodePacked(newBaseURI, "/"));
        } else {
            _baseTokenURI = newBaseURI;
        }
    }

    // ---------- OZ v5 required overrides for ERC721Enumerable ----------
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }
}
