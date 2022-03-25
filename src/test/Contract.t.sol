// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

import "ds-test/test.sol";
import "../Contract.sol";

interface CheatCodes {
  function warp(uint256) external;
}

contract ContractTest is DSTest, IERC721Receiver{
  CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
  Contract c;

  event Received();

  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external override returns(bytes4){
    _operator;
    _from;
    _tokenId;
    _data;
    emit Received();
    return 0x150b7a02;
  }

  uint256 saleStartEpoch = 1641070800;
  uint256 salePrice = 1 ether;

  function setUp() public {
    c = new Contract(10, 10);
    cheats.warp(saleStartEpoch);
    c.setSaleConfig(saleStartEpoch, saleStartEpoch, salePrice, salePrice);
  }

  function testSetSaleConfig() public {
    ( uint256 auctionSaleStartTime, uint256 publicSaleStartTime, uint256 allowlistPrice, uint256 publicPrice ) = c.saleConfig();

    assertEq(auctionSaleStartTime, saleStartEpoch);
    assertEq(publicSaleStartTime, saleStartEpoch);
    assertEq(allowlistPrice, salePrice);
    assertEq(publicPrice, salePrice);
  }

  function testSetAllowList() public {
    address[] memory arr = new address[](1);
    arr[0] = 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84;
    c.setAllowList(arr, 1);
    c.allowListMint{value: salePrice}();
    assertEq(c.balanceOf(address(this)), 1);
  }

  function testAuctionMint() public {
    c.auctionMint{value: salePrice }(1);
    assertEq(c.balanceOf(address(this)), 1);
  }

  function testPublicSaleMint() public {
    c.publicSaleMint{value: salePrice}(1);
    assertEq(c.balanceOf(address(this)), 1);
  }

  function testSetBaseUri() public {
    c.publicSaleMint{value: salePrice}(1);
    assertEq(c.balanceOf(address(this)), 1);

    c.setBaseURI("https://www.youtube.com/");
    assertEq(c.tokenURI(1), "https://www.youtube.com/1");
  }
}
