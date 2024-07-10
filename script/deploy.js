// scripts/create-box.js
const { ethers, upgrades } = require("hardhat");
const fs = require("fs");


async function main() {

  const [deployer] = await ethers.getSigners();
  const deployerAdd = deployer.address;
  const Operator = "0x53776974235A1a1F98d86e6295912D621580a242"; // Oracle operator
  const masterWallet = "0xF07531463fEa78eed4ee9C2739A5eF053992160F"; // incentive fee collector and liquidator
  const iZumiSwapContract = "0x4bD007912911f3Ee4b4555352b556B08601cE7Ce";
  const LiquidityOperator = "0x07142F5C572C3227fd710f2c94bd057d57aF1504";

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

  await APYContract.setVaultContract(vaultAdd).then(() => { console.log("vault contract set") })

  //////////////////////////////////////////////////////////////////////
  // const ERUSD = await ethers.getContractFactory("ERUSD");
  // const ERUSDToken = await ERUSD.deploy();
  // const ERUSDTokenAdd = ERUSDToken.address;
  // console.log("ERUSDToken deployed to:", ERUSDTokenAdd);


  // for Binance testnet 
  const ERUSD = await ethers.getContractFactory("ERUSD");
  const ERUSDToken = await ERUSD.attach("0xa640ABE09ACAdD71Ea580be4f2B6de46a5F45491");
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

  // For Eth classic testnet Oracle contract
  // const OraclePrice = await ethers.getContractFactory("OraclePrice");
  // const oraclePrice = await OraclePrice.attach("0xE79dBDc97F6655382467A81b0D4dAB3DD27fFaDa");
  // const oraclePriceAdd = oraclePrice.address;
  // console.log("oraclePrice deployed to:", oraclePriceAdd);

  //////////////////////////////////////////////////////////////////////
  const Swap = await ethers.getContractFactory("Swap");
  const swap = await Swap.deploy(iZumiSwapContract);
  const swapAdd = swap.address;
  console.log("swapAdd deployed to:", swapAdd);


  //////////////////////////////////////////////////////////////////////
  const Actions = await ethers.getContractFactory("Actions");
  const actions = await Actions.deploy(eTHJoinAdd, eRUSDJoinAdd, oraclePriceAdd, APYContractAdd, vaultAdd);
  const actionsAdd = actions.address;
  console.log("actions deployed to:", actionsAdd);

  //////////////////////////////////////////////////////////////////////
  const APYFactory = await ethers.getContractFactory("APYFactory");
  const apyFactory = await APYFactory.deploy(APYContractAdd);
  const apyFactoryAdd = apyFactory.address;
  console.log("apyFactory deployed to:", apyFactoryAdd);

  //////////////////////////////////////////////////////////////////////
  const APYMapper = await ethers.getContractFactory("APYMapper");
  const apyMapper = await APYMapper.deploy(apyFactoryAdd);
  const apyMapperAdd = apyMapper.address;
  console.log("apyMapper deployed to:", apyMapperAdd);

  //////////////////////////////////////////////////////////////////////
  const Liquidation = await ethers.getContractFactory("Liquidation");
  const liquidation = await Liquidation.deploy(vaultAdd, oraclePriceAdd, masterWallet, ERUSDTokenAdd, eTHJoinAdd, apyMapperAdd, LiquidityOperator);
  const liquidationAdd = liquidation.address;
  console.log("Liquidation :", liquidationAdd);

  await liquidation.setSwapContract(swapAdd).then(() => { console.log("authentic caller set") })

  await actions.setAPYMapper(apyMapperAdd).then(() => { console.log("APY mapper set in action") })

  await actions.setLiquidationContract(liquidationAdd).then(() => { console.log("liquidation set in action") })

  await actions.setAPYFactory(apyFactoryAdd).then(() => { console.log("APY factory set in actions") })

  await apyFactory.setAPYMapper(apyMapperAdd).then(() => { console.log("APY mapper set in factory") })

  await apyFactory.setAuthenticUser(actionsAdd).then(() => { console.log("Actions caller set in APYFActory") })

  await apyMapper.setAuthenticUser(apyFactoryAdd).then(() => { console.log("APY Factory caller set in APY Mapper") })

  await ERUSDToken.setAuthenticUser(eRUSDJoinAdd).then(() => { console.log("authentic caller set") })

  await vault.setAuthenticUser(eRUSDJoinAdd).then(() => { console.log("authentic caller set in vault") })

  await vault.setAuthenticUser(eRUSDJoinAdd).then(() => { console.log("authentic caller set in vault") })

  await vault.setAPYContract(APYContractAdd).then(() => { console.log("APY Contract set in vault") })

  await vault.setAuthenticUser(actionsAdd).then(() => { console.log("Actions Contract set in vault") })

  await vault.setAuthenticUser(eTHJoinAdd).then(() => { console.log("authentic caller set in vault") })

  await vault.setAuthenticUser(APYContractAdd).then(() => { console.log("authentic caller set in vault") })

  await eRUSDJoin.setAuthenticUser(actionsAdd).then(() => { console.log("Action caller set in ERUSD join") })

  await APYContract.setAuthenticUser(actionsAdd).then(() => { console.log("Action caller set in APY") })

  await APYContract.setAuthenticUser(apyFactoryAdd).then(() => { console.log("APYFActory caller set in APY") })

  await eTHJoin.setAuthenticUser(actionsAdd).then(() => { console.log("authentic caller set in ETH Join") })

  await eTHJoin.setAuthenticUser(liquidationAdd).then(() => { console.log("authentic caller set in ETH Join") })

  await ERUSDToken.setAuthenticUser(liquidationAdd).then(() => { console.log("authentic caller set in ERUSDToken") })

  await APYContract.setAuthenticUser(liquidationAdd).then(() => { console.log("authentic caller set in APY") })

  await vault.setAuthenticUser(liquidationAdd).then(() => { console.log("Actions Contract set in vault") })

  await vault.setOracleContract(oraclePriceAdd).then(() => { console.log("Oracle Contract set in vault") })

  await swap.setAuthenticUser(liquidationAdd).then(() => { console.log("authentic caller set in swap") })

  await APYContract.setAuthenticUser(vaultAdd).then(() => { console.log("authentic caller set in APYContract") })

  await transactionHistory.setAuthenticUser(vaultAdd).then(() => { console.log("authentic caller set in TransacionHistory") })

  //let ethersToWei = ethers.utils.parseUnits("0.01369", "ether");
  let bigAmount = ethers.BigNumber.from("13698630136986301");
  await apyMapper.addAPYDetails(APYContractAdd, bigAmount).then(() => { console.log("APY is added into mapper") })

  // let tokenAmount = ethers.utils.parseUnits("100", "ether");
  // await actions.lockAndDraw(deployer.address, tokenAmount, 150, { value: ethers.utils.parseEther("0.04188685739569726096") }).then(() => { console.log("created") })

  // await actions.lockAndDraw("0xf9313451BC943653De077132CbD24c30D24F762d", tokenAmount, 150, { value: ethers.utils.parseEther("0.04188685739569726096") }).then(() => { console.log("created") })

  // await actions.lockAndDraw("0x46d1e1Ea4b2EB3358a3029766E69306243542feb", tokenAmount, 150, { value: ethers.utils.parseEther("0.04188685739569726096") }).then(() => { console.log("created") })


  fs.appendFileSync(
    "./script/address.js",
    Buffer.from(
      `const deployer = "${deployerAdd}";
        const vaultAddress = "${vaultAdd}";  
        const ERUSD = "${ERUSDTokenAdd}";
        const ERUSDJoin = "${eRUSDJoinAdd}";
        const oracleAddress = "${oraclePriceAdd}";
        const actionsContract = "${actionsAdd}";
        const swapContract = "${swapAdd}";
        const LiquidationContract = "${liquidationAdd}";
        const APYFactoryContract = "${apyFactoryAdd}";
        const APYMapperContract = "${apyMapperAdd}";
        const currentTime = "${new Date()}";
        `
    ),
    (err) => {
      console.error(err);
    }
  );
}

main();
