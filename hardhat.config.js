require("@nomicfoundation/hardhat-toolbox");
// require("@nomiclabs/hardhat-ethers");
// require("@nomiclabs/hardhat-etherscan");
require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.18"
  },
  // networks: {
  //   goerli: {
  //     url: `https://eth-goerli.alchemyapi.io/v2/${alchemyApiKey}`, //thay doi
  //     accounts: { mnemonic: mnemonic }, //thay doi
  //   },
  // },
  paths: {
    artifacts: "./abi"
  },
  networks:{
    bsctest:{
      url: 'https://data-seed-prebsc-2-s2.binance.org:8545',
      accounts: [process.env.PRIV_KEY]
    }
  },
  etherscan: {
    apiKey: process.env.API_KEY
  }

};