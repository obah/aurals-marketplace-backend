const pinataSDK = require("@pinata/sdk");
require("dotenv").config();

const pinataApiKey = process.env.PINATA_API_KEY;
const pinataApiSecret = process.env.PINATA_API_SECRET;
const pinata = pinataSDK(pinataApiKey, pinataApiSecret);

async function storeImages(imageFile) {
    let responses = [];
    console.log("uploading to IPFS by Pinata!");
    try {
        const response = await pinata.pinFileToIPFS(imageFile);
        responses.push(response);
    } catch (error) {
        console.log(error);
    }

    return { responses, imageFile };
}

async function storeTokenUriMetadata(metadata) {
    try {
        const response = await pinata.pinJSONToIPFS(metadata);
        return response;
    } catch (error) {
        console.log(error);
    }
    return null;
}

module.exports = { storeImages, storeTokenUriMetadata };
