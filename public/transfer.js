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
        const _EKWowner = await walletContract.methods.owner().call();
        console.log(_EKWowner);

        // Get the deployed wallet contract balance. (Dont call contract using privatekey but use account address.)
        await walletContract.methods.Balanceof().call({from: process.env.MY_ACCOUNT_ADDRESS}).then(console.log);

        const _EKWbalance = await walletContract.methods.Balanceof().call({from: process.env.MY_ACCOUNT_ADDRESS});
        console.log(`Wallet Contract balance: ${_EKWbalance}`);
        
        // Submit transaction from wallet contract.
        const SubmitTx = await walletContract.methods.SubmitTransaction(process.env.RECIPIENT_ADDRESS, 100)
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

        // const ConfirmTx = await walletContract.methods.ConfirmTransaction(0)
        //     .call({from: process.env.MY_ACCOUNT_ADDRESS});

        // const ExecuteTx = await walletContract.methods.ExecuteTransaction(0)
        //     .send({from: process.env.MY_ACCOUNT_ADDRESS});

        //await walletContract.methods.Transactions(0).call({from: process.env.MY_ACCOUNT_ADDRESS}).then(console.log);

        //const withdraw = await walletContract.methods.Withdraw().sendTransaction({from: process.env.MY_META_WALLET});

        // const submitTx = await walletContract.methods.SubmitTransaction(process.env.RECIPIENT_ADDRESS, 900);//.send({ from: process.env.MY_META_WALLET, gas:200000 });
        // console.log('Transaction submitted:', submitTx.transactionHash);
        // const events = await walletContract.getPastEvents('submitTransaction',{ fromBlock: 0, toBlock: 'latest' });
        //     //.on('data', async function (event){
        //         const _txIndex = event.returnValues.txIndex;
        //         console.log(_txIndex);

        //         const confirmTX = await walletContract.methods.ConfirmTransaction(_txIndex);//.send({ from: process.env.MY_META_WALLET });
        //         console.log("TX Confirmed");

        //         const exeTx = await walletContract.methods.ExecuteTransaction(_txIndex);//.send({ from: process.env.MY_META_WALLET });
        //         console.log("executed");
        //     //})
          
    }catch (err){
        console.error(err);
    }
}
transfer();