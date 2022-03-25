# Contract

## setSaleConfig

```solidity
setSaleConfig(uint256 auctionSaleStartTime, uint256 allowlistSaleStartTime, uint256 publicSaleStartTime, uint256 allowlistPrice, uint256 publicPrice)
```

Parameters **:**

- **auctionSaleStartTime** : Auction start time in epoch unix.
- **allowlistSaleStartTime** : Allowlist start time in epoch unix.
- **publicSaleStartTime** : Public start in epoch unix.
- **allowlistPrice** : Allowlist mint price in wei unit.
- **publicPrice** : Public mint price in wei unit.

Epoch unix converter

[https://eth-converter.com/](https://eth-converter.com/)

Unit converter

[https://www.unixtimestamp.com/](https://www.unixtimestamp.com/)

---

## setAllowList

```solidity
setAllowList(address[] calldata addresses, uint256 numAllowedToMint)
```

Parameters :

- **addresses** : Address list in object.
- **numAllowedToMint** : Number allowed to mint.

---

## setBaseURI

```solidity
setBaseURI(string calldata _baseTokenURI)
```

Parameters :

- **_baseTokenURI** : Base token IPFS uri.

---

## Dutch Auction

```solidity
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
```

Variables :

- **AUCTION_START_PRICE** : Auction start price.
- **AUCTION_END_PRICE** : Auction end price.
- **AUCTION_PRICE_CURVE_LENGTH** : Auction time length.
- **AUCTION_DROP_INTERVAL** : Auction drop interval
