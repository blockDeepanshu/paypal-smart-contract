require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");

require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.9",
    networks: {
      testnet: {
        url: "https://rpc.ankr.com/polygon_mumbai",
        accounts: [`0x${process.env.PRIVATE_KEY}`],
      },
    },
    etherscan: {
      apiKey: process.env.API_KEY,
    },
  },
};
