require("@nomicfoundation/hardhat-toolbox");

require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

const END_POINT_ETHC = process.env.ETHC;

// Add .ENV file to get your private key and RPCs of networks
const key = process.env.PRIVATE_KEY;

// /** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.7",
      },
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],

  },
  networks: {
    ETHClassic: {
      url: END_POINT_ETHC,
      accounts: [key],
    }
  },
  settings: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
};
