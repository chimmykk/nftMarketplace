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


    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

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
            price,
            false
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
            price,
            false
        );
    }

    // put the item up for sale
    function createMarketSale(
        address nftContract,
        uint256 itemId
    ) public payable nonReentrant {
        uint price = idToMarketItem[itemId].price;
        uint tokenId = idToMarketItem[itemId].tokenId;

        require(msg.value == price, "Please input the asking price: ");

        // transfer the value sent into this transaction (NFT) to the seller
        idToMarketItem[itemId].seller.transfer(msg.value);

        // transfer NFT from the buyer to the seller
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

        // the owner being the one who gets paid
        idToMarketItem[itemId].owner = payable(msg.sender);
        idToMarketItem[itemId].sold = true;

        // number of items sold goes up by 1
        _itemSold.increment();

        // when item is sold, transfer listing price to the marketplace owner as commission
        payable(owner).transfer(listingPrice);
    }

     // fetch items currently available for sale
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        // total number of items created so far
        uint itemCount = _itemIds.current();

        /// items still unsold
        uint unsoldItemCount = _itemIds.current() - _itemSold.current();
        
        // to iterate over the items array
        uint currentIndex = 0;

        // initiate an array of unsold items
        MarketItem[] memory items = new MarketItem[](unsoldItemCount);

        for (uint i = 0; i < itemCount; i++) {
            // if there's no buyer yet
            if (idToMarketItem[i + 1].owner == address(0)) {
                // set current item's id
                uint currentId = idToMarketItem[i + 1].itemId;
                // find current item using its id
                MarketItem storage currentItem = idToMarketItem[currentId];
                // populate items array with the item yet unsold
                items[currentIndex] = currentItem;
                // increment index
                currentIndex += 1;
            }
        }
        return items;
    }

    // fetch items owned by the user
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            // if the user is owner of the item
            if (idToMarketItem[i + 1].owner == msg.sender) {
                // increment item count by one
                itemCount += 1;
            }
        } 

        // initiate an array of owned items
        MarketItem[] memory items = new MarketItem[](itemCount);
        
        for (uint i = 0; i < totalItemCount; i++) {
            // if user owns the asset
            if (idToMarketItem[i + 1].owner == msg.sender) {
                uint currentId = idToMarketItem[i + 1].itemId;
                // add item to array
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }    
        }

        return items;
    }

    
}