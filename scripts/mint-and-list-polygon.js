const { ethers } = require("hardhat");
const commonPrice = ethers.utils.parseEther("50");
const rarePrice = ethers.utils.parseEther("200");
const superRarePrice = ethers.utils.parseEther("1000");
const { handleTokenUris } = require("../utils/resolveTokenUri");

const commonInput = "common";
const rareInput = "rare";
const superRareInput = "superRare";
const collectionSize = 100;
const collectionName = "the lion is a lion";

async function mintAndListCollection() {
    //check how this getContract function works and note how it will get the contract on polygon testnet
    const nftMarketplace = await ethers.getContract("NftMarketplace"); //replace with address
    const nft = await ethers.getContract("NFT"); //replace with address

    const commonTokenUris = await handleTokenUris(commonInput);
    const commonTokenUri = commonTokenUris[0];

    const rareTokenUris = await handleTokenUris(rareInput);
    const rareTokenUri = rareTokenUris[0];

    const superRareTokenUris = await handleTokenUris(superRareInput);
    const superRareTokenUri = superRareTokenUris[0];

    console.log("Minting Collection...");
    const mintTx = await nft.mintCollection(
        commonTokenUri,
        rareTokenUri,
        superRareTokenUri,
        collectionSize
    );
    const mintTxReceipt = await mintTx.wait(1);
    const tokenIds = [];
    for (i = 0; i <= collectionSize; i++) {
        const tokenId = mintTxReceipt.events[i].args.tokenId;
        tokenIds.push(tokenId);
    }

    console.log("Approving NFT collection...");
    for (i = 0; i <= tokenIds.length; i++) {
        selectedTokenId = tokenIds[i];
        const approvalTx = await nft.approve(
            nftMarketplace.address,
            selectedTokenId
        );
        await approvalTx.wait(1);
    }

    console.log("Listing NFT collection...");
    const tx = await nftMarketplace.makeCollection(
        nft.address,
        commonPrice,
        rarePrice,
        superRarePrice,
        collectionSize,
        collectionName
    );
    await tx.wait(1);
    console.log("Listed!");
}

mintAndListCollection()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
