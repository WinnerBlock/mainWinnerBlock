// truffle-config for local testing only
// const HDWalletProvider = require('@truffle/hdwallet-provider');
// const fs = require('fs');
// const mnemonic = fs.readFileSync(".secret").toString().trim();

module.exports = {
  networks: {
     development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*",
     },
  compilers: {
    solc: {
      version: "0.8.7",
      settings: {
        optimizer: {
          enabled: true,
          runs: 800
        },
       }
    }
  },
};
