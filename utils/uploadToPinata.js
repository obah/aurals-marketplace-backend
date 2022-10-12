const pinataSDK = require("@pinata/sdk");
const path = require("path");
const fs = require("fs");
require("dotenv").config();

const pinataApiKey = process.env.PINATA_API_KEY;
const pinataApiSecret = process.env.PINATA_API_SECRET;
const pinata = pinataSDK(pinataApiKey, pinataApiSecret);

async function storeImages(imagesFilePath) {
    const fullImagesPath = path.resolve(imagesFilePath); // resturns the absolute path
    const files = fs.readdirSync(fullImagesPath); // gets files in a directory
    let responses = [];
    console.log("uploading to IPFS by Pinata!");
    for (fileIndex in files) {
        console.log(`Working on ${fileIndex}...`);
        const readableStreamForFile = fs.createReadStream(
            // gets the content of a file
            `${fullImagesPath}/${files[fileIndex]}`
        );
        try {
            const response = await pinata.pinFileToIPFS(readableStreamForFile);
            responses.push(response);
        } catch (error) {
            console.log(error);
        }
    }
    return { responses, files };
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
