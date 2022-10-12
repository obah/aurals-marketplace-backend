const { ethers, network } = require("hardhat");
const PRICE = ethers.utils.parseEther("0.1");
const { moveBlocks } = require("../utils/move-blocks");
const { handleTokenUris } = require("../utils/resolveTokenUri");

async function mintAndList() {
    const nftMarketplace = await ethers.getContract("NftMarketplace");
    const nft = await ethers.getContract("NFT");

    const tokenUris = await handleTokenUris();
    const tokenUri = tokenUris[0];

    console.log("Minting...");
    const mintTx = await nft.mint(tokenUri);
    const mintTxReceipt = await mintTx.wait(1);
    const tokenId = mintTxReceipt.events[0].args.tokenId;

    console.log("Approving NFT...");
    const approvalTx = await nft.approve(nftMarketplace.address, tokenId);
    await approvalTx.wait(1);

    console.log("Listing NFT...");
    const tx = await nftMarketplace.makeItem(nft.address, tokenId, PRICE);
    await tx.wait(1);
    console.log("Listed!");

    if (network.config.chainId == "31337") {
        await moveBlocks(1, (sleepAmount = 1000));
    }
}

mintAndList()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
