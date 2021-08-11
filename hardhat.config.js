require("@nomiclabs/hardhat-waffle");

// TODO: put in process env
const projectId = "3cec794156614711b12732157f6e4100"

module.exports = {
  networks: {
    // local node
    hardhat: {
      chainId: 1337,
    },
    mumbai: {
      url: `https://polygon-mumbai.infura.io/v3/${projectId}`,
      // accounts from which we deploy
      account: []
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${projectId}`
    },
  },
  solidity: "0.8.4",
};
