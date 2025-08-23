
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AuroraPulseNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 999;
    string private _baseTokenURI;
    bool public mintActive = false;
    bool public metadataLocked = false;

    mapping(address => bool) public hasMinted;

    event MintActiveSet(bool active);
    event BaseURISet(string newBaseURI);
    event MetadataLocked();
    event FreeMint(address indexed to, uint256 indexed tokenId);
    event OwnerMint(address indexed to, uint256 quantity);

    constructor() ERC721("Aurora Pulse NFT", "APN") Ownable(msg.sender) {
        _setBaseURIInternal("https://gateway.lighthouse.storage/ipfs/bafybeidtzm6gnixqtgntxctay23aep5edjglo2z2jjtoa3du2onmbtby2i/");
    }

    // ---------- Public Mint ----------
    function freeMint() external nonReentrant {
        require(mintActive, "Mint not active");
        require(!hasMinted[msg.sender], "Already minted");

        // OPTIONAL anti-bot (commented). Not bulletproof; blocks many simple bots.
        // require(tx.origin == msg.sender, "No contracts");

        uint256 currentSupply = totalSupply();
        require(currentSupply < MAX_SUPPLY, "Sold out");

        uint256 tokenId = currentSupply + 1; // 1..MAX_SUPPLY
        hasMinted[msg.sender] = true;       // set BEFORE external call
        _safeMint(msg.sender, tokenId);

        emit FreeMint(msg.sender, tokenId);
    }

    // ---------- Owner Reserve / Airdrop ----------
    function ownerMint(address to, uint256 quantity) external onlyOwner {
        require(quantity > 0, "quantity=0");
        uint256 currentSupply = totalSupply();
        require(currentSupply + quantity <= MAX_SUPPLY, "Exceeds supply");

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = totalSupply() + 1;
            _safeMint(to, tokenId);
        }

        emit OwnerMint(to, quantity);
    }

    // ---------- Admin ----------
    function setMintActive(bool active) external onlyOwner {
        mintActive = active;
        emit MintActiveSet(active);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        require(!metadataLocked, "Metadata locked");
        _setBaseURIInternal(newBaseURI);
        emit BaseURISet(_baseTokenURI);
    }

    function lockMetadata() external onlyOwner {
        metadataLocked = true;
        emit MetadataLocked();
    }


    // ---------- Views ----------
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // OZ v5: _ownerOf is OK; or use _requireOwned(tokenId)
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
