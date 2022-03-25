// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import './ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract Contract is ERC721A, Ownable, ReentrancyGuard{
    uint256 public immutable maxPerAddressDuringMint;

    error requireUserOnly();
    error requireMoreFund();
    error requireWhitelisted();
    error requirePublicSaleOn();
    error requireAuctionOn();
    error reachMaxMintPerAddress();
    error reachMaxSupply();
    error withdrawFailed();

    struct SaleConfig {
      uint256 auctionSaleStartTime;
      uint256 publicSaleStartTime;
      uint256 allowlistPrice;
      uint256 publicPrice;
    }

    SaleConfig public saleConfig;

    mapping(address => uint256) public allowList;

    constructor (
        uint256 maxBatchSize_,
        uint256 collectionSize_
    ) ERC721A('Vestige', 'VESTIGE', maxBatchSize_, collectionSize_) {
        maxPerAddressDuringMint = maxBatchSize_;
    }

    modifier callerIsUser() {
        if (tx.origin != msg.sender) revert requireUserOnly();
        _;
    }

    function setSaleConfig(uint256 auctionSaleStartTime, uint256 publicSaleStartTime, uint256 allowlistPrice, uint256 publicPrice) external onlyOwner {
        saleConfig = SaleConfig(
            auctionSaleStartTime,
            publicSaleStartTime,
            allowlistPrice,
            publicPrice
        );
    }

    function setAllowList(address[] calldata addresses, uint256 numAllowedToMint) external onlyOwner {
        unchecked {
            for (uint256 i = 0; i < addresses.length; i++) {
                allowList[addresses[i]] = numAllowedToMint;
            }
        }
    }

    function allowListMint() external payable {
        uint256 allowlistPrice = saleConfig.allowlistPrice;
        if (msg.value < allowlistPrice) revert requireMoreFund();
        if (allowList[msg.sender] <= 0 ) revert requireWhitelisted();

        allowList[msg.sender]--;
        _safeMint(msg.sender, 1);
        refundIfOver(allowlistPrice);
    }

    function publicSaleMint(uint256 numberOfTokens) external payable {
        uint256 publicPrice = saleConfig.publicPrice;
        uint256 publicSaleStartTime = saleConfig.publicSaleStartTime;
        if (!isPublicSaleOn(publicPrice, publicSaleStartTime)) revert requirePublicSaleOn();
        if (msg.value < publicPrice) revert requireMoreFund();
        if (_numberMinted(msg.sender) + numberOfTokens > maxPerAddressDuringMint) revert reachMaxMintPerAddress();
        if (totalSupply() + numberOfTokens > _collectionSize) revert reachMaxSupply();

        _safeMint(_msgSender(), numberOfTokens);
        refundIfOver(publicPrice * numberOfTokens);
    }

    function auctionMint(uint256 numberOfTokens) external payable  {
        uint256 _saleStartTime = saleConfig.auctionSaleStartTime;
        if (_saleStartTime == 0 && block.timestamp <= _saleStartTime) revert requireAuctionOn();
        if (_numberMinted(msg.sender) + numberOfTokens > maxPerAddressDuringMint) revert reachMaxMintPerAddress();
        if (totalSupply() + numberOfTokens > _collectionSize) revert reachMaxSupply();

        uint256 totalCost = getAuctionPrice(_saleStartTime) * numberOfTokens;
        if (msg.value < totalCost) revert requireMoreFund();

        _safeMint(msg.sender, numberOfTokens);
        refundIfOver(totalCost);
    }

    function devMint(uint256 numberOfTokens) external payable onlyOwner {
        _safeMint(msg.sender, numberOfTokens);
    }

    function refundIfOver(uint256 price) private {
      if (msg.value > price) {
        payable(msg.sender).transfer(msg.value - price);
      }
    }

    uint256 public constant AUCTION_START_PRICE = 1 ether;
    uint256 public constant AUCTION_END_PRICE = 0.15 ether;
    uint256 public constant AUCTION_PRICE_CURVE_LENGTH = 340 minutes;
    uint256 public constant AUCTION_DROP_INTERVAL = 20 minutes;
    uint256 public constant AUCTION_DROP_PER_STEP =
      (AUCTION_START_PRICE - AUCTION_END_PRICE) /
        (AUCTION_PRICE_CURVE_LENGTH / AUCTION_DROP_INTERVAL);

    function getAuctionPrice(uint256 _saleStartTime) public view returns (uint256){
      if (block.timestamp < _saleStartTime) {
          return AUCTION_START_PRICE;
      }
      if (block.timestamp - _saleStartTime >= AUCTION_PRICE_CURVE_LENGTH) {
          return AUCTION_END_PRICE;
      } else {
          uint256 steps = (block.timestamp - _saleStartTime) /
            AUCTION_DROP_INTERVAL;
          return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);
      }
    }

    function isPublicSaleOn(uint256 publicPriceWei, uint256 publicSaleStartTime) public view returns (bool) {
        return publicPriceWei != 0 && block.timestamp >= publicSaleStartTime;
    }

    // Metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert withdrawFailed();
    }
}