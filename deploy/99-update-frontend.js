const { ethers, network } = require("hardhat");
const fs = require("fs");

const marketplaceContractsFile =
    "../FRONTEND/aurals-nft-marketplace/constants/nftMarketplaceNetworkMapping.json";
const nftContractsFile =
    "../FRONTEND/aurals-nft-marketplace/constants/nftNetworkMapping.json";
const frontEndAbiLocation = "../FRONTEND/aurals-nft-marketplace/constants/";

module.exports = async function () {
    if (process.env.UPDATE_FRONT_END) {
        console.log("updating frontend...");
        await updateContractAddresses();
        await updateAbi();
    }
};

async function updateAbi() {
    const nftMarketplace = await ethers.getContract("NftMarketplace");
    fs.writeFileSync(
        `${frontEndAbiLocation}NftMarketplace.json`,
        nftMarketplace.interface.format(ethers.utils.FormatTypes.json)
    );

    const nft = await ethers.getContract("NFT");
    fs.writeFileSync(
        `${frontEndAbiLocation}NFT.json`,
        nft.interface.format(ethers.utils.FormatTypes.json)
    );
}

async function updateContractAddresses() {
    const nftMarketplace = await ethers.getContract("NftMarketplace");
    const nft = await ethers.getContract("NFT");
    const chainId = network.config.chainId.toString();
    const marketplaceContractAddress = JSON.parse(
        fs.readFileSync(marketplaceContractsFile, "utf8")
    );
    const nftContractAddress = JSON.parse(
        fs.readFileSync(nftContractsFile, "utf8")
    );

    if (chainId in marketplaceContractAddress) {
        if (
            !marketplaceContractAddress[chainId]["NftMarketplace"].includes(
                nftMarketplace.address
            )
        ) {
            marketplaceContractAddress[chainId]["NftMarketplace"].push(
                nftMarketplace.address
            );
        }
    } else {
        marketplaceContractAddress[chainId] = {
            NftMarketplace: [nftMarketplace.address],
        };
    }
    fs.writeFileSync(
        marketplaceContractsFile,
        JSON.stringify(marketplaceContractAddress)
    );

    if (chainId in nftContractAddress) {
        if (!nftContractAddress[chainId]["NFT"].includes(nft.address)) {
            nftContractAddress[chainId]["NFT"].push(nft.address);
        }
    } else {
        nftContractAddress[chainId] = {
            NFT: [nft.address],
        };
    }
    fs.writeFileSync(nftContractsFile, JSON.stringify(nftContractAddress));
}

module.exports.tags = ["all", "frontend", "polygonAll"];
