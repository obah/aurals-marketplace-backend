const { ethers, network } = require("hardhat");
const { moveBlocks } = require("../utils/move-blocks");

const TOKEN_ID = 2;

async function buyItem() {
    const nftMarketplace = await ethers.getContract("NftMarketplace");
    const nft = await ethers.getContract("NFT");
    const item = await nftMarketplace.getItem(nft.address, TOKEN_ID);
    const price = item.price.toString();
    const tx = await nftMarketplace.purchaseItem(nft.address, TOKEN_ID, {
        value: price,
    });
    await tx.wait(1);
    console.log("Bought NFT");
    if (network.config.chainId == "31337") {
        await moveBlocks(1, (sleepAmount = 1000));
    }
}

buyItem()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
