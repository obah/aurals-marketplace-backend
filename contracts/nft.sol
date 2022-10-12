//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

/// @title NFT
/// @author Obaloluwa T. Olusoji
/// @notice This contract creates an NFT with different specified rarities and if possible, music albums as its metadata
/// @dev Ensure the mintCollection and makeCollection(from marketplace contract) correlate on tokenID and tokenURI to classes
contract NFT is ERC721URIStorage {
    uint256 private s_tokenCount;

    event NftMinted(uint256 indexed tokenId);

    constructor() ERC721("Aurals NFT", "AuNFT") {
        s_tokenCount = 0;
    }

    function mint(string memory _tokenURI) public {
        _safeMint(msg.sender, s_tokenCount);
        _setTokenURI(s_tokenCount, _tokenURI);
        emit NftMinted(s_tokenCount);

        s_tokenCount += 1;
    }

    function getTokenCount() public view returns (uint256) {
        return s_tokenCount;
    }

    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        return tokenURI(tokenId);
    }

    ////////////////////
    //AURALS FUNCTION //
    ////////////////////
    function mintCollection(
        string memory commonTokenURI,
        string memory rareTokenURI,
        string memory superRareTokenURI,
        uint256 collectionSize
    ) public {
        uint256 commonSize = (75 * collectionSize) / 100;
        uint256 rareSize = (20 * collectionSize) / 100;
        uint256 superRareSize = (5 * collectionSize) / 100;
        if (commonSize + rareSize + superRareSize < collectionSize) {
            superRareSize = collectionSize - (commonSize + rareSize);
        } else if (commonSize + rareSize + superRareSize > collectionSize) {
            superRareSize = superRareSize - 1;
        }

        //mint common NFTs
        for (uint256 i = 0; i <= commonSize; i++) {
            mint(commonTokenURI);
        }
        //mint rare NFTs
        for (uint256 i = 0; i <= rareSize; i++) {
            mint(rareTokenURI);
        }
        //mint super rare NFTs
        for (uint256 i = 0; i <= superRareSize; i++) {
            mint(superRareTokenURI);
        }
    }
}
