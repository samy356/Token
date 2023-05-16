const {ethers} =  require ("hardhat");

async function main(){
    const Wallet = await ethers.getContractFactory("EKWallet");
    const wallet = await Wallet.deploy();

    await wallet.deployed();

    console.log(`Wallet deployed to ${wallet.address}`);
}

main(). catch((error) => {
    console.error (error);
    process.exitCode = 1;
})