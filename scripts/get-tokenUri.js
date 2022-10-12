const { ethers, network } = require("hardhat");

const tokenId = 0;

async function getTokenUri() {
    const nft = await ethers.getContract("NFT");
    const Tx = await nft.tokenURI(tokenId);
    console.log(`The tokenURI for NFT ${nft.address} at ${tokenId} is: ${Tx}`);
}

getTokenUri()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
