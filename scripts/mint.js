const { ethers, network } = require("hardhat");
const { moveBlocks } = require("../utils/move-blocks");
const { handleTokenUris } = require("../deploy/02-deploy-nft-ipfs");

async function mint() {
    const nft = await ethers.getContract("NFT");

    const tokenUris = await handleTokenUris();
    const tokenUri = tokenUris[0];

    console.log("Minting...");
    const mintTx = await nft.mint(tokenUri);
    const mintTxReceipt = await mintTx.wait(1);
    const tokenId = mintTxReceipt.events[0].args.tokenId;
    console.log(`Minted NFT ${tokenId} at address ${nft.address}`);

    if (network.config.chainId == "31337") {
        await moveBlocks(1, (sleepAmount = 1000));
    }
}

mint()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
