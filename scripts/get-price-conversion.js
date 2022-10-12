const { ethers } = require("hardhat");

const TOKEN_ID = 25;
async function getPrice() {
    const nftMarketplace = await ethers.getContract("NftMarketplace"); //replace with address
    const nft = await ethers.getContract("NFT"); //replace with address
    const item = await nftMarketplace.getItem(nft.address, TOKEN_ID);
    const price = item.price.toString();
    console.log(`Price of item in MATIC: ${price} MATIC`);
    console.log("---------------------------------------");
    const usdPrice = await nftMarketplace.getMaticPriceConversion(
        nft.address,
        TOKEN_ID
    );
    await usdPrice.wait(1);
    console.log(`Price of the item in USD: ${usdPrice} USD`);
    console.log("---------------------------------------");
    const ethPrice = await nftMarketplace.getMaticToEthPrice(
        nft.address,
        TOKEN_ID
    );
    await ethPrice.wait(1);
    console.log(`Price of the item in ETH: ${ethPrice} ETH`);
    console.log("---------------------------------------");
}

getPrice()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
