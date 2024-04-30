# Smart Contract Deployment

Welcome to the Smart Contract Deployment repository! This guide helps you deploy smart contracts using Hardhat to your preferred blockchain network.

## Quick Start

1. **Clone the Repository:**
   - Open Visual Studio Code (VS Code)
   - Open New Terminal (Ctrl+Shift+`)
   - git clone https://github.com/your-username/smart-contract-deployment.git
   - cd smart-contract-deployment


2. **Set Up Environment:**
- Install the latest version of [Node.js](https://nodejs.org/).
- Create a `.env` file in the root directory and add:
  ```
  BLOCKCHAIN = ETHC
  ETHC_RPC_URL = https://geth-mordor.etc-network.info/
  PRIVATE_KEY = "your private key"
  ```

3. **Install Dependencies:**
- Run the following command in the terminal:
  ```
  npm install
  ```
This command is used to install dependencies listed in the `package.json` file.

4. **Compile Contracts:**
- Open terminal
- npx hardhat compile

5. **Deploy Contracts:**
- Open terminal
- Open terminal 
- npx hardhat run ./scripts/deploy.js --network "your network"

This command deploys all contracts and sets authentication for contract-to-contract calls.

## Using Remix IDE

1. **Open Remix IDE:**
- Open Remix in your browser [here](https://remix.ethereum.org/#lang=en&optimize=false&runs=200&evmVersion=null&version=soljson-v0.8.18+commit.87f61d96.js).

2. **Import Contract:**
- In Remix, click on the file icon on the left sidebar, then select "Import". Choose the Solidity file from your project's contracts folder.

3. **Compile Contracts:**
- After importing, Remix will automatically compile the contracts. You can see the compiled artifacts in the "Compile" tab.

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.
