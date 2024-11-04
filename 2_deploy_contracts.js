// Import contracts
const CapybaraToken = artifacts.require("CapybaraToken");
const CapybaraNFTGate = artifacts.require("CapybaraNFTGate");
const CapybaraDispenser = artifacts.require("CapybaraDispenser");

module.exports = async function (deployer, network, accounts) {
    // Deploy CapybaraToken, passing the owner's address as the constructor argument
    await deployer.deploy(CapybaraToken, accounts[0]); // Passing accounts[0] as the owner
    const capybaraToken = await CapybaraToken.deployed();

    // Deploy CapybaraNFTGate without additional parameters if it doesn't require them
    await deployer.deploy(CapybaraNFTGate, "Capybara NFT Gate", "CAPYBARA-GATE");
    const capybaraNFTGate = await CapybaraNFTGate.deployed();

    // Deploy CapybaraDispenser with the addresses of CapybaraToken and CapybaraNFTGate and a URI for the external service
    await deployer.deploy(
        CapybaraDispenser,
        capybaraToken.address,           // Address of the deployed CapybaraToken
        capybaraNFTGate.address,         // Address of the deployed CapybaraNFTGate
        "https://capybara.io/proxy"  // Replace this later with the actual URI for the external service (our proxi that connects to NFT Storage IPFS)
    );
};
