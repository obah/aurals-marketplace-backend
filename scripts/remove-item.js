const { ethers, network } = require("hardhat");
const { moveBlocks } = require("../utils/move-blocks");

const TOKEN_ID = 0; //parse in a variable here

async function removeItem() {
    const nftMarketplace = await ethers.getContract("NftMarketplace");
    const nft = await ethers.getContract("NFT");
    const tx = await nftMarketplace.removeListing(nft.address, TOKEN_ID);
    await tx.wait(1);
    console.log("NFT removed");
    if (network.config.chainId == "31337") {
        await moveBlocks(1, (sleepAmount = 1000));
    }
}

removeItem()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
