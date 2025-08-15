// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract StellarNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 299;
    string private _baseTokenURI;
    bool public mintActive;
    mapping(address => bool) public hasMinted;

    event MintActiveSet(bool active);
    event BaseURISet(string newBaseURI);
    event FreeMint(address indexed to, uint256 tokenId);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory initialBaseURI_
    ) ERC721(name_, symbol_) Ownable(msg.sender) {
        _setBaseURIInternal(initialBaseURI_);
    }

    function freeMint() external nonReentrant {
        require(mintActive, "Mint not active");
        require(!hasMinted[msg.sender], "Already minted");
        require(totalSupply() < MAX_SUPPLY, "Sold out");

        uint256 tokenId = totalSupply() + 1;
        hasMinted[msg.sender] = true;
        _safeMint(msg.sender, tokenId);

        emit FreeMint(msg.sender, tokenId);
    }

    function setMintActive(bool active) external onlyOwner {
        mintActive = active;
        emit MintActiveSet(active);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _setBaseURIInternal(newBaseURI);
        emit BaseURISet(_baseTokenURI);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), ".json"));
    }

    function _setBaseURIInternal(string memory newBaseURI) internal {
        require(bytes(newBaseURI).length > 0, "Empty URI");
        if (bytes(newBaseURI)[bytes(newBaseURI).length - 1] != "/") {
            _baseTokenURI = string(abi.encodePacked(newBaseURI, "/"));
        } else {
            _baseTokenURI = newBaseURI;
        }
    }

    // Required overrides
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

