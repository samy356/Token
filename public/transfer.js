const Web3  = require('web3');
//const Web3C = require('web3-eth-contract');
const Path = require('path');
require ('dotenv').config({path : Path.resolve(__dirname, "../.env")});

//const ethers = require('ethers');
//Web3C.setProvider(`https://polygon-mumbai.infura.io/v3/${process.env.INFURA_API_KEY}`);
const tokenABI = require("../artifacts/contracts/Token.sol/Token.json").abi;
const walletABI = require("../artifacts/contracts/Wallet.sol/EKWallet.json").abi;
const tokenAddress = process.env._tokenAddress;
const walletAddress = process.env._walletAddress;

//console.log(walletABI);
async function transfer(){
    try{
        const web3 = new Web3(`https://polygon-mumbai.infura.io/v3/${process.env.INFURA_API_KEY}`);
        const tokenContract = new web3.eth.Contract(tokenABI, tokenAddress);
        const walletContract = new web3.eth.Contract(walletABI, walletAddress);
        //console.log(walletContract);
       
        //await tokenContract.methods.balanceof(walletAddress).call().then(console.log);
        const Balance = await tokenContract.methods.balanceOf(walletAddress).call();
        console.log(`Balance: ${Balance}`);

        // Get the owner of wallet contract deployed.
        const _EKWowner = await walletContract.methods.OwnerAddress().call({from: process.env.MY_ACCOUNT_ADDRESS});
        console.log(_EKWowner);

        await walletContract.methods.MapToken(tokenAddress).call({from: process.env.MY_ACCOUNT_ADDRESS}).then(console.log("Done"));

        // Get the deployed wallet contract balance. (Dont call contract using privatekey but use account address.)
        await walletContract.methods.Balanceof(tokenAddress).call({from: process.env.MY_ACCOUNT_ADDRESS}).then(console.log);

        const _EKWbalance = await walletContract.methods.Balanceof(tokenAddress).call({from: process.env.MY_ACCOUNT_ADDRESS});
        console.log(`Wallet Contract balance: ${_EKWbalance}`);
        
        // Submit transaction from wallet contract.
        const SubmitTx = await walletContract.methods.SubmitTransaction(tokenAddress, process.env.RECIPIENT_ADDRESS, 100)
            .send({from: process.env.MY_ACCOUNT_ADDRESS}).on('receipt', function(receipt){console.log(receipt);});

        // walletContract.events.submitTransaction()
        //     .on('data', event => {
        //         console.log(`Transaction submitted by ${event.returnValues.owner} at index ${event.returnValues.txIndex}`);
        //     })
        //     .on('error', console.error);

        async () => {
            const events = await walletContract.getPastEvents('submitTransaction', {
                fromBlock: 'latest',
                toBlock: 'latest',
            });
            
            console.log('Events:', events);
        }
          
    }catch (err){
        console.error(err);
    }
}
transfer();