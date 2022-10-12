//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title A smart contract for the functions of a nft marketplace
/// @author Obaloluwa T. Olusoji
/// @notice You can use this smart contract for a music nft marketplace
/// @dev Add pricefeed

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error NftMarketplace__InvalidPrice();
error NftMarketplace__InvalidClassPriceDifference();
error NftMarketplace__InvalidItemId();
error NftMarketplace__InsufficientAmount(
    address nftAddress,
    uint256 tokenId,
    uint256 price
);
error NftMarketplace__NotApproved();
error NftMarketplace__NotOwner();
error NftMarketplace__AlreadyListed(address nftAddress, uint256 tokenId);
error NftMarketplace__NotListed(address nftAddress, uint256 tokenId);
error NftMarketplace__TransferToMarketplaceFailed();
error NftMarketplace__TransferToCreatorFailed();
error NftMarketplace__TransferToResellerFailed();
error NftMarketplace__WithdrawalFailed();
error NftMarketplace__CollectionSizeTooLow();

contract NftMarketplace is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private itemCount; //used for tokenID & total items listed
    Counters.Counter private marketItemsCount; //used for current items listed

    AggregatorV3Interface public ethPriceFeed;
    AggregatorV3Interface public maticPriceFeed;

    address payable public immutable i_feeAccount;
    uint256 public immutable i_feePercent;

    struct Item {
        address nftAddress;
        uint256 tokenId;
        uint256 price;
        address payable seller;
        address payable creator;
        string collectionName;
        string creatorName;
        string itemClass;
        bool resell;
    }

    //NftMarketplace contact address -> NFT token Id -> Item
    mapping(address => mapping(uint256 => Item)) private s_items;

    // Used to hold the earnings an user has made
    mapping(address => uint256) private s_amountEarned;
    //Used to hold all items created by an address
    mapping(address => uint256[]) private s_itemsCreated;

    event ItemOffered(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        address indexed seller,
        string collectionName,
        string creatorName,
        address creatorAddress,
        string itemClass,
        bool resale
    );

    event ItemBought(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        address seller,
        address indexed buyer,
        string collectionName
    );

    event ItemRemoved(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        string collectionName
    );

    event CollectionListed(
        string indexed creatorName,
        address nftAddress,
        uint256 collectionSize,
        string indexed collectionName,
        address creatorAddress,
        uint256 commonSize,
        uint256 rareSize,
        uint256 superRareSize,
        uint256 indexed finalTokenId,
        uint256 startingPrice
    );

    constructor() {
        i_feeAccount = payable(msg.sender);
        i_feePercent = 3;
        ethPriceFeed = AggregatorV3Interface(
            0x0715A7794a1dc8e42615F059dD6e406A6594651A
        );
        maticPriceFeed = AggregatorV3Interface(
            0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
        );
    }

    ///////////////////
    // MODIFIERS     //
    ///////////////////

    modifier notListed(address nftAddress, uint256 tokenId) {
        Item memory item = s_items[nftAddress][tokenId];
        if (item.price > 0) {
            revert NftMarketplace__AlreadyListed(nftAddress, tokenId);
        }
        _;
    }

    modifier alreadyListed(address nftAddress, uint256 tokenId) {
        Item memory item = s_items[nftAddress][tokenId];
        if (item.price <= 0) {
            revert NftMarketplace__NotListed(nftAddress, tokenId);
        }
        _;
    }

    modifier isOwner(
        address nftAddress,
        uint256 tokenId,
        address seller
    ) {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        if (seller != owner) {
            revert NftMarketplace__NotOwner();
        }
        _;
    }

    modifier isApproved(address nftAddress, uint256 tokenId) {
        IERC721 nft = IERC721(nftAddress);
        if (nft.getApproved(tokenId) != address(this)) {
            revert NftMarketplace__NotApproved();
        }
        _;
    }

    modifier validPrice(uint256 price) {
        if (price <= 0) {
            revert NftMarketplace__InvalidPrice();
        }
        _;
    }

    receive() external payable {}

    ////////////////////
    // MAIN FUNCTIONS //
    ////////////////////

    /// @notice This functions lists an item in the marketplace and allows an user to resell an item they bought
    /// @dev This contract also acts as an escrow for the nft sales and allows prople to hold their nft after listing
    /// @param nftAddress: Address of the NFT
    /// @param tokenId: token id of the NFT
    /// @param price: price the nft sells for
    function makeItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        string memory _collectionName,
        string memory _creatorName,
        string memory _itemClass
    )
        public
        notListed(nftAddress, tokenId)
        isApproved(nftAddress, tokenId)
        validPrice(price)
        nonReentrant
    {
        address payable creator;
        string memory collectionName;
        string memory creatorName;
        string memory itemClass;
        bool reselling;
        if (tokenId == itemCount.current()) {
            creator = payable(msg.sender);
            //this might be exploitable, if users can set the tokenID themselves, either make it immutable or dont let them set tokenID at all
            //so that people dont have to enter this values when reselling do this;
            collectionName = _collectionName; //get this 3 from the item from the frontend when someone wants to resell an item
            creatorName = _creatorName;
            itemClass = _itemClass;
            reselling = false;
        } else {
            creator = s_items[nftAddress][tokenId].creator;
            collectionName = s_items[nftAddress][tokenId].collectionName;
            creatorName = s_items[nftAddress][tokenId].creatorName;
            itemClass = s_items[nftAddress][tokenId].itemClass;
            reselling = true;
        }

        //add new item to s_items mapping
        s_items[nftAddress][itemCount.current()] = Item(
            nftAddress,
            tokenId,
            price,
            payable(msg.sender),
            payable(creator),
            collectionName,
            creatorName,
            itemClass,
            reselling
        );
        //increment item count
        itemCount.increment();
        marketItemsCount.increment();
        //emit offered event
        emit ItemOffered(
            nftAddress,
            tokenId,
            price,
            msg.sender,
            collectionName,
            creatorName,
            creator,
            itemClass,
            reselling
        );
    }

    function makeCollection(
        address nftAddress,
        uint256 commonPrice,
        uint256 rarePrice,
        uint256 superRarePrice,
        uint256 collectionSize,
        string memory collectionName,
        string memory creatorName,
        string memory itemClass
    ) external nonReentrant {
        if (rarePrice < commonPrice || superRarePrice < rarePrice) {
            revert NftMarketplace__InvalidClassPriceDifference();
        }

        if (collectionSize < 100) {
            revert NftMarketplace__CollectionSizeTooLow();
        }

        uint256 commonSize = (75 * collectionSize) / 100;
        uint256 rareSize = (20 * collectionSize) / 100;
        uint256 superRareSize = (5 * collectionSize) / 100;
        if (commonSize + rareSize + superRareSize < collectionSize) {
            superRareSize = collectionSize - (commonSize + rareSize);
        } else if (commonSize + rareSize + superRareSize > collectionSize) {
            superRareSize = superRareSize - 1;
        }
        uint256[] memory userItems = s_itemsCreated[msg.sender];
        uint256 index;
        if (userItems.length == 0) {
            index = 0;
        } else {
            index = userItems.length;
        }
        //Creates common items
        for (uint256 i = 0; i <= commonSize; i++) {
            uint256 tokenId = itemCount.current();
            makeItem(
                nftAddress,
                tokenId,
                commonPrice,
                collectionName,
                creatorName,
                itemClass //check if you have to set the specific class here or in frontend
            );
            userItems[index] = tokenId;
            index++;
        }
        //Creates rare items
        for (uint256 i = 0; i <= rareSize; i++) {
            uint256 tokenId = itemCount.current();
            makeItem(
                nftAddress,
                tokenId,
                rarePrice,
                collectionName,
                creatorName,
                itemClass
            );
            userItems[index] = tokenId;
            index++;
        }
        //Creates super rare items
        for (uint256 i = 0; i <= superRareSize; i++) {
            uint256 tokenId = itemCount.current();
            makeItem(
                nftAddress,
                tokenId,
                superRarePrice,
                collectionName,
                creatorName,
                itemClass
            );
            userItems[index] = tokenId;
            index++;
        }

        uint256 finalTokenId = itemCount.current() - 1;

        emit CollectionListed(
            creatorName,
            nftAddress,
            collectionSize,
            collectionName,
            msg.sender,
            commonSize,
            rareSize,
            superRareSize,
            finalTokenId,
            commonPrice
        );
    }

    //Allows a buyer to buy an NFT from a seller
    /// @notice Allows users to buy NFTs from the marketplace collection
    /// @dev Because of solidity intent, we will make users withdraw their funds instead of transfer it to them directly
    /// @param nftAddress: contact address for the nft to be bought
    /// @param tokenId: used to represent the token id of the nft to be bought
    function purchaseItem(address nftAddress, uint256 tokenId)
        external
        payable
        nonReentrant
    {
        Item storage item = s_items[nftAddress][tokenId];
        if (tokenId < 0 || tokenId > itemCount.current()) {
            revert NftMarketplace__InvalidItemId();
        }
        if (msg.value < item.price) {
            revert NftMarketplace__InsufficientAmount(
                nftAddress,
                tokenId,
                item.price
            );
        }

        //Set the market fee and seller's new amount
        uint256 marketShare = (item.price * i_feePercent) / 100;
        uint256 newAmount;
        uint256 creatorShare = item.price / 10; //10% is creator's share
        address payable creator = item.creator;
        //pay seller, fee account and creator account
        if (creator == item.seller) {
            newAmount = item.price - marketShare;
            //store total value of earnings for reporting
            s_amountEarned[address(this)] =
                s_amountEarned[address(this)] +
                marketShare;
            s_amountEarned[creator] = s_amountEarned[creator] + newAmount;
            //transfer earnings to respective addresses

            //transfer proceeds to seller
            (bool success1, ) = payable(creator).call{value: newAmount}("");
            if (!success1) {
                revert NftMarketplace__TransferToCreatorFailed();
            }

            //transfer market fee to smart contract
            (bool success2, ) = payable(i_feeAccount).call{value: marketShare}(
                ""
            );
            if (!success2) {
                revert NftMarketplace__TransferToMarketplaceFailed();
            }
        } else {
            newAmount = item.price - marketShare - creatorShare;
            //store total value of earnings for reporting
            s_amountEarned[address(this)] =
                s_amountEarned[address(this)] +
                marketShare;
            s_amountEarned[item.seller] =
                s_amountEarned[item.seller] +
                newAmount;
            s_amountEarned[creator] = s_amountEarned[creator] + creatorShare;
            //transfer earnings to respective addresses

            //transfer proceeds to seller
            (bool success1, ) = payable(item.seller).call{value: newAmount}("");
            if (!success1) {
                revert NftMarketplace__TransferToResellerFailed();
            }

            //transfer market fee to smart contract
            (bool success2, ) = payable(i_feeAccount).call{value: marketShare}(
                ""
            );
            if (!success2) {
                revert NftMarketplace__TransferToMarketplaceFailed();
            }

            //transfer royalty to item creator (artist)
            (bool success3, ) = payable(creator).call{value: creatorShare}("");
            if (!success3) {
                revert NftMarketplace__TransferToCreatorFailed();
            }
        }
        item.price = 0; //this is for the notListed and alreadyListed modifiers

        //transfer nft to buyer
        IERC721(nftAddress).safeTransferFrom(
            item.seller,
            msg.sender,
            item.tokenId
        );

        delete (s_items[nftAddress][tokenId]);
        marketItemsCount.decrement();

        //emit bought event
        emit ItemBought(
            nftAddress,
            tokenId,
            item.price,
            item.seller,
            msg.sender,
            item.collectionName
        );
    }

    function removeListing(address nftAddress, uint256 tokenId)
        external
        isOwner(nftAddress, tokenId, msg.sender)
        alreadyListed(nftAddress, tokenId)
    {
        string memory collectionName = s_items[nftAddress][tokenId]
            .collectionName;
        delete (s_items[nftAddress][tokenId]);
        marketItemsCount.decrement();
        emit ItemRemoved(msg.sender, nftAddress, tokenId, collectionName);
    }

    function updateListing(
        address nftAddress,
        uint256 tokenId,
        uint256 newPrice
    )
        external
        isOwner(nftAddress, tokenId, msg.sender)
        alreadyListed(nftAddress, tokenId)
    {
        Item memory item = s_items[nftAddress][tokenId];
        item.price = newPrice;
        emit ItemOffered(
            nftAddress,
            item.tokenId,
            newPrice,
            msg.sender,
            item.collectionName,
            item.creatorName,
            item.creator,
            item.itemClass,
            item.resell
        );
    }

    /// @notice Allows users to withdraw earnings from the smart contract
    /// @dev Transfers earning from smart contract to user address
    /// @dev Requirements; must be owner of smartcontract
    /// @param userAddress Address of the admin
    function withdrawEarnings(address payable userAddress) external {
        require(
            msg.sender == i_feeAccount,
            "only smart contract owner can call this function"
        );
        uint256 earning = i_feeAccount.balance;
        (bool success, ) = payable(userAddress).call{value: earning}("");
        if (!success) {
            revert NftMarketplace__WithdrawalFailed();
        }
    }

    ////////////////////
    // SUB FUNCTIONS  //
    ////////////////////

    function getItem(address nftAddress, uint256 tokenId)
        external
        view
        returns (Item memory)
    {
        return s_items[nftAddress][tokenId];
    }

    function getEarning(address userAddress) external view returns (uint256) {
        return s_amountEarned[userAddress];
    }

    function getUserListedItems(address nftAddress, address userAddress)
        external
        view
        returns (Item[] memory)
    {
        uint256[] memory userItems = s_itemsCreated[userAddress];
        Item[] memory userItemsArray;
        for (uint256 i = 0; i <= userItems.length; i++) {
            uint256 tokenId = userItems[i];
            Item storage selectedUserItem = s_items[nftAddress][tokenId];
            userItemsArray[i] = selectedUserItem;
        }
        return userItemsArray;
    }

    function setCollectionName(string memory _collectionName)
        public
        view
        returns (string memory)
    {
        string memory collectionName = _collectionName;
        return collectionName;
    }

    function setCreatorName(string memory _creatorName)
        public
        view
        returns (string memory)
    {
        string memory creatorName = _creatorName;
        return creatorName;
    }

    //////////////////////
    // PRICE FUNCTIONS  //
    //////////////////////
    function getEthPriceConversion(address nftAddress, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        (, int256 price, , , ) = ethPriceFeed.latestRoundData();
        uint256 ethPrice = uint256(price * 1e10);

        Item storage item = s_items[nftAddress][tokenId];
        uint256 priceInCrypto = item.price;
        uint256 priceInUSD = (ethPrice * priceInCrypto) / 1e18;
        return priceInUSD;
    }

    function getMaticPriceConversion(address nftAddress, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        (, int256 price, , , ) = maticPriceFeed.latestRoundData();
        uint256 maticPrice = uint256(price * 1e10);

        Item storage item = s_items[nftAddress][tokenId];
        uint256 priceInCrypto = item.price;
        uint256 priceInUSD = (maticPrice * priceInCrypto) / 1e18;
        return priceInUSD;
    }

    function getMaticToEthPrice(address nftAddress, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        (, int256 price, , , ) = ethPriceFeed.latestRoundData();
        uint256 ethPrice = uint256(price * 1e10);
        uint256 priceInUsd = getMaticPriceConversion(nftAddress, tokenId);
        uint256 priceInEth = (priceInUsd / ethPrice) / 1e18;
        return priceInEth;
    }

    function getEthToMaticPrice(address nftAddress, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        (, int256 price, , , ) = maticPriceFeed.latestRoundData();
        uint256 maticPrice = uint256(price * 1e10);
        uint256 priceInUsd = getEthPriceConversion(nftAddress, tokenId);
        uint256 priceInMatic = (priceInUsd / maticPrice) / 1e18;
        return priceInMatic;
    }
}
