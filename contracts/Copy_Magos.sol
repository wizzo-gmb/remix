/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: MIT AND GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



// File: contracts/magos.sol

pragma solidity >=0.7.0 <0.9.0;



contract magos is ERC721Enumerable, Ownable {
  using Strings for uint256;
  string private baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public preSaleCost = 0.001 ether;
  uint256 public price = 0.001 ether;
  uint256 public MAX_SUPPLY = 9999;
  uint256 public preSaleMaxSupply = 2250;
  uint256 public maxMintAmountPresale = 1;
  uint256 public MAX_MULTIMINT = 10;
  uint256 public nftPerAddressLimitPresale = 1;
  uint256 public nftPerAddressLimit = 100;
  uint256 public preSaleDate = 1638738000;
  uint256 public preSaleEndDate = 1638824400;
  uint256 public publicSaleDate = 1638842400;
  bool public paused = false;
  bool public revealed = false;
 // mapping(address => bool) whitelistedAddresses;
  mapping(address => uint256) public addressMintedBalance;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setNotRevealedURI(_initNotRevealedUri);
  }

  //MODIFIERS
  modifier notPaused {
    require(!paused, "the contract is paused");
    _;
  }

  modifier saleStarted {
    require(block.timestamp >= preSaleDate, "Sale has not started yet");
    _;
  }

  modifier minimumMintAmount(uint256 count) {
    require(count > 0, "need to mint at least 1 NFT");
    _;
  }

  // INTERNAL
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function presaleValidations(
    uint256 _ownerMintedCount,
    uint256 count,
    uint256 _supply
  ) internal {
    uint256 actualCost;
    block.timestamp < preSaleEndDate
      ? actualCost = preSaleCost
      : actualCost = price;
   // require(isWhitelisted(msg.sender), "user is not whitelisted");
    require(
      _ownerMintedCount + count <= nftPerAddressLimitPresale,
      "max NFT per address exceeded for presale"
    );
    require(msg.value >= actualCost * count, "insufficient funds");
    require(
      count <= maxMintAmountPresale,
      "max mint amount per transaction exceeded"
    );
    require(
      _supply + count <= preSaleMaxSupply,
      "max NFT presale limit exceeded"
    );
  }

  function publicsaleValidations(uint256 _ownerMintedCount, uint256 count)
    internal
  {
    require(
      _ownerMintedCount + count <= nftPerAddressLimit,
      "max NFT per address exceeded"
    );
    require(msg.value >= price * count, "insufficient funds");
    require(
      count <= MAX_MULTIMINT,
      "max mint amount per transaction exceeded"
    );
  }

  //MINT
  function mint(uint256 count)
    public
    payable
    notPaused
    saleStarted
    minimumMintAmount(count)
  {
    uint256 supply = totalSupply();
    uint256 ownerMintedCount = addressMintedBalance[msg.sender];

    //Do some validations depending on which step of the sale we are in
    block.timestamp < publicSaleDate
      ? presaleValidations(ownerMintedCount, count, supply)
      : publicsaleValidations(ownerMintedCount, count);

    require(supply + count <= MAX_SUPPLY, "max NFT limit exceeded");

    for (uint256 i = 1; i <= count; i++) {
      addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }

  function gift(uint256 count, address destination) public onlyOwner {
    require(count > 0, "need to mint at least 1 NFT");
    uint256 supply = totalSupply();
    require(supply + count <= MAX_SUPPLY, "max NFT limit exceeded");

    for (uint256 i = 1; i <= count; i++) {
      addressMintedBalance[destination]++;
      _safeMint(destination, supply + i);
    }
  }

  //PUBLIC VIEWS
 // function isWhitelisted(address _user) public view returns (bool) {
 //   return whitelistedAddresses[_user];
 // }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (!revealed) {
      return notRevealedUri;
    } else {
      string memory currentBaseURI = _baseURI();
      return
        bytes(currentBaseURI).length > 0
          ? string(
            abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)
          )
          : "";
    }
  }

  function getCurrentCost() public view returns (uint256) {
    if (block.timestamp < preSaleEndDate) {
      return preSaleCost;
    } else {
      return price;
    }
  }

  //ONLY OWNER VIEWS
  function getBaseURI() public view onlyOwner returns (string memory) {
    return baseURI;
  }

  function getContractBalance() public view onlyOwner returns (uint256) {
    return address(this).balance;
  }

  //ONLY OWNER SETTERS
  function reveal() public onlyOwner {
    revealed = true;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function setNftPerAddressLimitPreSale(uint256 _limit) public onlyOwner {
    nftPerAddressLimitPresale = _limit;
  }

  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }

  function setPresaleCost(uint256 _newCost) public onlyOwner {
    preSaleCost = _newCost;
  }

  function setCost(uint256 _newCost) public onlyOwner {
    price = _newCost;
  }

  function setmaxMintAmountPreSale(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmountPresale = _newmaxMintAmount;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    MAX_MULTIMINT = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setPresaleMaxSupply(uint256 _newPresaleMaxSupply) public onlyOwner {
    preSaleMaxSupply = _newPresaleMaxSupply;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    MAX_SUPPLY = _maxSupply;
  }

  function setPreSaleDate(uint256 _preSaleDate) public onlyOwner {
    preSaleDate = _preSaleDate;
  }

  function setPreSaleEndDate(uint256 _preSaleEndDate) public onlyOwner {
    preSaleEndDate = _preSaleEndDate;
  }

  function setPublicSaleDate(uint256 _publicSaleDate) public onlyOwner {
    publicSaleDate = _publicSaleDate;
  }

 // function whitelistUsers(address[] memory addresses) public onlyOwner {
 //   for (uint256 i = 0; i < addresses.length; i++) {
 //     whitelistedAddresses[addresses[i]] = true;
 //   }
 // }

  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{ value: address(this).balance }(
      ""
    );
    require(success);
  }
}