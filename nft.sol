// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 * BAYC-style ERC721
 * - tokenURI = baseURI + tokenId + ".json"
 * - Free mint (1 per wallet), capped at 299
 * - Owner can reserve mint for airdrops
 * - Base URI set to given IPFS CID
 */

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract StellarNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 299;
    string private _baseTokenURI;
    bool public mintActive = false;

    mapping(address => bool) public hasMinted;

    event MintActiveSet(bool active);
    event BaseURISet(string newBaseURI);
    event FreeMint(address indexed to, uint256 tokenId);

    constructor() ERC721("StellarNFT", "STELLAR") Ownable(msg.sender) {
        _setBaseURIInternal("https://gateway.lighthouse.storage/ipfs/bafybeibbbcwjfeufaykqfdorz2n35xakxgqabfxynlowx5ggz7ls6vexdq/");
    }

    // ---------- Public Mint ----------
    function freeMint() external nonReentrant {
        require(mintActive, "Mint not active");
        require(!hasMinted[msg.sender], "Already minted");

        uint256 currentSupply = totalSupply();
        require(currentSupply < MAX_SUPPLY, "Sold out");

        uint256 tokenId = currentSupply + 1;
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
        require(_ownerOf(tokenId) != address(0), "Query for nonexistent token");
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), ".json"));
    }

    // ---------- Internal ----------
    function _setBaseURIInternal(string memory newBaseURI) internal {
        require(bytes(newBaseURI).length > 0, "Empty URI");
        bytes memory b = bytes(newBaseURI);
        if (b[b.length - 1] != "/") {
            _baseTokenURI = string(abi.encodePacked(newBaseURI, "/"));
        } else {
            _baseTokenURI = newBaseURI;
        }
    }

    // ---------- Overrides ----------
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable) returns (bool) {
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
