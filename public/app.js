const { artifacts } = require('hardhat');
const Web3 = require('web3');
const Path = require('path');
require ('dotenv').config({path : path.resolve(__dirname, "../.env")});

const web3 = new Web3(`https://polygon-mumbai.infura.io/v3/${process.env.INFURA_API_KEY}`); // Replace with your local node URL

const contractAddress = '0x3C500Ec85234E8871b9aDf60Bee4412765a0C6c6'; // Replace with your deployed contract address
const abi = require('../artifacts/contracts/Token.sol/Token.json').abi; // Replace with your contract ABI

const contract = new web3.eth.Contract(abi, contractAddress);

async function getTokenDetails() {
  const name = await contract.methods.name().call();
  const symbol = await contract.methods.symbol().call();
  const totalSupply = await contract.methods.totalSupply().call();
  const tokenAddress = contractAddress;

  console.log('Token Name:', name);
  console.log('Token Symbol:', symbol);
  console.log('Total Supply:', totalSupply);
  console.log('Token Address:', tokenAddress);
}

getTokenDetails();