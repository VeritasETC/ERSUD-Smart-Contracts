const { ethers, upgrades } = require("hardhat");

async function main() {

    const ActionContract = "action contract address";

    const [deployer] = await ethers.getSigners();
    const deployerAdd = deployer.address;
    console.log("Deploying contracts with the account:", deployerAdd);

    const Actions = await ethers.getContractFactory("Actions");
    const actions = await Actions.attach(ActionContract);

    let percentage = ethers.utils.parseUnits("0.001", "ether")
    let daySeconds = 60
    await actions.updateAPY(percentage, daySeconds).then(() => { console.log("APY update method called") })

}

main();
