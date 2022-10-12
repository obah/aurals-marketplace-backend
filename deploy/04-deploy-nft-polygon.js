const { network } = require("hardhat");
const { handleTokenUris } = require("../utils/resolveTokenUri");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();
    tokenUris = args = [];

    const nft = await deploy("NFT", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    });

    if (process.env.UPLOAD_TO_PINATA == "true") {
        tokenUris = await handleTokenUris();
    }

    log("-----------------------------------------");
};

module.exports.tags = ["polygonAll", "polygonNft"];
