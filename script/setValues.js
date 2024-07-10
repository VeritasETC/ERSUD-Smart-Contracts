// scripts/create-box.js
const { ethers, upgrades } = require("hardhat");
const fs = require("fs");


async function main() {

    const [deployer] = await ethers.getSigners();
    const deployerAdd = deployer.address;
    const masterWallet = "0xF07531463fEa78eed4ee9C2739A5eF053992160F";

    console.log("Deploying contracts with the account:", deployerAdd);

    const TransactionHistory = await ethers.getContractFactory("TransactionHistory");
    const transactionHistory = await TransactionHistory.attach("0x0135c1df21FfE63F616b75011069E66da81Fd5Cd");

    await transactionHistory.transferOwnership(masterWallet).then(() => { console.log("ownership transferred") })

    //////////////////////////////////////////////////////////////////////
    const Vault = await ethers.getContractFactory("Vault");
    const vault = await Vault.attach("0xf63eB45d48359D027482926ea25734CaBc1A7764");
    await vault.transferOwnership(masterWallet).then(() => { console.log("ownership transferred") })

    // for Binance testnet 
    // const ERUSD = await ethers.getContractFactory("ERUSD");
    // const ERUSDToken = await ERUSD.attach("0x1F9E67aa7f6022323601Be87fa1b80Ef4224Ec5b");
    // await ERUSDToken.transferOwnership(masterWallet).then(() => { console.log("ownership transferred") })

    //////////////////////////////////////////////////////////////////////
    const ERUSDJoin = await ethers.getContractFactory("ERUSDJoin");
    const eRUSDJoin = await ERUSDJoin.attach("0x01311e4C659f44190309C9333A738B11750B896e");
    await eRUSDJoin.transferOwnership(masterWallet).then(() => { console.log("ownership transferred") })

    //////////////////////////////////////////////////////////////////////
    const ETHJoin = await ethers.getContractFactory("ETCJoin");
    const eTHJoin = await ETHJoin.attach("0xf89AF5699bb2fEFD0c77e848D2522617d109F3d9");
    await eTHJoin.transferOwnership(masterWallet).then(() => { console.log("ownership transferred") })

    //////////////////////////////////////////////////////////////////////
    const OraclePrice = await ethers.getContractFactory("OraclePrice");
    const oraclePrice = await OraclePrice.attach("0x3f618A078C19A6e45cC71c57fF13bAE102BBFc20");
    await oraclePrice.transferOwnership(masterWallet).then(() => { console.log("ownership transferred") })

    //////////////////////////////////////////////////////////////////////
    const Swap = await ethers.getContractFactory("Swap");
    const swap = await Swap.attach("0xC4242D8CA6706dd601d5b16D0C0e2fFedaA6303E");
    await swap.transferOwnership(masterWallet).then(() => { console.log("ownership transferred") })

    //////////////////////////////////////////////////////////////////////
    const Actions = await ethers.getContractFactory("Actions");
    const actions = await Actions.attach("0xEAEF128585cF2DB9E7000b741255899D2E6ce944");
    await actions.transferOwnership(masterWallet).then(() => { console.log("ownership transferred") })

    //////////////////////////////////////////////////////////////////////
    const APYFactory = await ethers.getContractFactory("APYFactory");
    const apyFactory = await APYFactory.attach("0x55d40BA9A66BDdBa92De741E9D45A302cA209ada");
    await apyFactory.transferOwnership(masterWallet).then(() => { console.log("ownership transferred") })

    //////////////////////////////////////////////////////////////////////
    const APYMapper = await ethers.getContractFactory("APYMapper");
    const apyMapper = await APYMapper.attach("0x77252B8de9C08900af6fA05852e324Da255947A6");
    await apyMapper.transferOwnership(masterWallet).then(() => { console.log("ownership transferred") })

    //////////////////////////////////////////////////////////////////////
    const Liquidation = await ethers.getContractFactory("Liquidation");
    const liquidation = await Liquidation.attach("0x97C3E9cb7ed75Be9AF554995a4dCec46109f5728");
    await liquidation.transferOwnership(masterWallet).then(() => { console.log("ownership transferred") })

}

main();
