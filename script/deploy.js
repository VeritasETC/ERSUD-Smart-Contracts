// scripts/create-box.js
const { ethers, upgrades } = require("hardhat");
const fs = require("fs");


async function main() {

  const [deployer] = await ethers.getSigners();
  const deployerAdd = deployer.address;
  const Operator = "add operator address you want as payer in script";

  console.log("Deploying contracts with the account:", deployerAdd);

  const TransactionHistory = await ethers.getContractFactory("TransactionHistory");
  const transactionHistory = await TransactionHistory.deploy();
  const transactionHistoryAdd = transactionHistory.address;
  console.log("transactionHistory deployed to:", transactionHistoryAdd);

  //////////////////////////////////////////////////////////////////////
  const APY = await ethers.getContractFactory("APY");
  const APYContract = await APY.deploy();
  const APYContractAdd = APYContract.address;
  console.log("APYContract deployed to:", APYContractAdd);

  //////////////////////////////////////////////////////////////////////
  const Vault = await ethers.getContractFactory("Vault");
  const vault = await Vault.deploy(APYContractAdd, transactionHistoryAdd);
  const vaultAdd = vault.address;
  console.log("vault deployed to:", vaultAdd);

  //////////////////////////////////////////////////////////////////////
  const ERUSD = await ethers.getContractFactory("ERUSD");
  const ERUSDToken = await ERUSD.deploy();
  const ERUSDTokenAdd = ERUSDToken.address;
  console.log("ERUSDToken deployed to:", ERUSDTokenAdd);


  //////////////////////////////////////////////////////////////////////
  const ERUSDJoin = await ethers.getContractFactory("ERUSDJoin");
  const eRUSDJoin = await ERUSDJoin.deploy(vaultAdd, ERUSDTokenAdd);
  const eRUSDJoinAdd = eRUSDJoin.address;
  console.log("ERUSDJoin deployed to:", eRUSDJoinAdd);

  //////////////////////////////////////////////////////////////////////
  const ETHJoin = await ethers.getContractFactory("ETCJoin");
  const eTHJoin = await ETHJoin.deploy(vaultAdd);
  const eTHJoinAdd = eTHJoin.address;
  console.log("ETHJoin deployed to:", eTHJoinAdd);

  //////////////////////////////////////////////////////////////////////
  const OraclePrice = await ethers.getContractFactory("OraclePrice");
  const oraclePrice = await OraclePrice.deploy(Operator);
  const oraclePriceAdd = oraclePrice.address;
  console.log("oraclePrice deployed to:", oraclePriceAdd);

  //////////////////////////////////////////////////////////////////////
  const Liquidation = await ethers.getContractFactory("Liquidation");
  const liquidation = await Liquidation.deploy(vaultAdd, oraclePriceAdd);
  const liquidationAdd = liquidation.address;
  console.log("Liquidation :", liquidationAdd);


  //////////////////////////////////////////////////////////////////////
  const Actions = await ethers.getContractFactory("Actions");
  const actions = await Actions.deploy(eTHJoinAdd, eRUSDJoinAdd, oraclePriceAdd, APYContractAdd, vaultAdd);
  const actionsAdd = actions.address;
  console.log("actions deployed to:", actionsAdd);

  await ERUSDToken.setAuthenticUser(eRUSDJoinAdd).then(() => { console.log("authentic caller set") })

  await vault.setAuthenticUser(eRUSDJoinAdd).then(() => { console.log("authentic caller set in vault") })

  await vault.setAPYContract(APYContractAdd).then(() => { console.log("APY Contract set in vault") })

  await vault.setAuthenticUser(actionsAdd).then(() => { console.log("Actions Contract set in vault") })

  await vault.setAuthenticUser(eTHJoinAdd).then(() => { console.log("authentic caller set in vault") })

  await eRUSDJoin.setAuthenticUser(actionsAdd).then(() => { console.log("authentic caller set in ERUSD join") })

  await APYContract.setAuthenticUser(actionsAdd).then(() => { console.log("authentic caller set in APY") })

  await eTHJoin.setAuthenticUser(actionsAdd).then(() => { console.log("authentic caller set in ETH Join") })

  await APYContract.setAuthenticUser(vaultAdd).then(() => { console.log("authentic caller set in APYContract") })

  await transactionHistory.setAuthenticUser(vaultAdd).then(() => { console.log("authentic caller set in TransacionHistory") })

  fs.writeFileSync(
    "./script/address.js",
    Buffer.from(
      `const deployer = "${deployerAdd}";
        const vaultAddress = "${vaultAdd}";  
        const ERUSD = "${ERUSDTokenAdd}";
        const ERUSDJoin = "${eRUSDJoinAdd}";
        const oracleAddress = "${oraclePriceAdd}";
        const actionsContract = "${actionsAdd}";
        const LiquidationContract = "${liquidationAdd}";
        `
    ),
    (err) => {
      console.error(err);
    }
  );
}

main();
