//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    address payable owner;
    uint256 listingPrice = 0.025 ether;

    constructor() {
        owner = payable(msg.sender);
    }

    //each item will have properties:
    struct MarketItem {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        bool sold;
    }

    // create an index of id to the item
    mapping(uint256 => MarketItem) private idToMarketItem;

    // update changes to new item
    event MarketItemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint indexed tokenId,
        address seller,
        address owner,
        uint256 price
    );

    // create item
    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant {
        require(price >= 0, "Price must be more than 0, you savvy genius!");
        // when an item is being created, confirm that the gas fee has been paid
        require(msg.value == listingPrice, "Price must include listing price");

        // increment the id
        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        // map item to its id
        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            // payable to the owner
            payable(msg.sender),
            // no buyers yet
            payable(address(0)),
            price
        );

        // transfer NFT from owner to buyer
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        // trigger creation of the new item
        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender, 
            address(0),
            price
        );
    }
}