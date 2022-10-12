const {
    storeImages,
    storeTokenUriMetadata,
} = require("./uploadToPinataFrontend");

const metadataTemplate = {
    name: "",
    description: "",
    image: "",
    properties: {
        artist: "",
        work: "",
        class: "",
    },
};

let tokenUris;

async function handleTokenUris(
    artistNameInput,
    workNameInput,
    classTypeInput,
    imageLocation
) {
    tokenUris = [];
    const { responses: imageUploadResponses, files } = await storeImages(
        imageLocation
    );
    for (imageUploadResponseIndex in imageUploadResponses) {
        let tokenUriMetadata = { ...metadataTemplate };
        tokenUriMetadata.name = files[imageUploadResponseIndex].replace(
            ".jpg",
            ""
        );
        tokenUriMetadata.description = `Aural NFT for music album: ${tokenUriMetadata.name}`;
        tokenUriMetadata.image = `ipfs://${imageUploadResponses[imageUploadResponseIndex].IpfsHash}`;
        tokenUriMetadata.properties.artist = artistNameInput;
        tokenUriMetadata.properties.work = workNameInput;
        if (classTypeInput == "common") {
            tokenUriMetadata.properties.class = "Common";
        } else if (classTypeInput == "rare") {
            tokenUriMetadata.properties.class = "Rare";
        } else if (classTypeInput == "superRare") {
            tokenUriMetadata.properties.class = "Super Rare";
        }
        console.log(`Uploading ${tokenUriMetadata.name}...`);
        const metadataUploadResponse = await storeTokenUriMetadata(
            tokenUriMetadata
        );

        tokenUris.push(`ipfs://${metadataUploadResponse.IpfsHash}`);

        console.log("Token URI Uploaded! They are: ");
        console.log(tokenUris);
        return tokenUris;
    }
}

module.exports = { handleTokenUris };
