//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

//Single Owner Wallet
contract EKWallet{

    event deposit(address indexed sender, uint amount);
    event submitTransaction(address indexed sender, uint txIndex, uint amount, address to);
    event confirmTransaction(address indexed owner, uint txIndex);
    event executeTransaction(address indexed owner, uint txIndex);

    address public owner;

    struct transaction{
        address to;
        uint value;
        bool txConfirmed;
        bool txExecuted;
    }

    transaction[] public Transactions;
    bool private locked;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require (msg.sender == owner, "You are not the Owner of this account");
        _;
    }
    modifier txExist(uint _txIndex){
        require (_txIndex <= Transactions.length && _txIndex>=0, "Transaction do not exist");
        _;
    }
    modifier txNotConfirmed(uint _txIndex){
        require (!Transactions[_txIndex].txConfirmed, "Transaction already confirmed");
        _;
    }
    modifier txNotExecuted(uint _txIndex){
        require (!Transactions[_txIndex].txExecuted, "Transaction already executed");
        _;
    }
    modifier txConfirmed(uint _txIndex){
        require (Transactions[_txIndex].txConfirmed, "Transaction not confirmed");
        _;
    }
    modifier nonRentrant(){
        require (!locked, "Contract is being executed");
        locked = true;
        _;
        locked = false;
    }

    function TransferOwnership(address _to) public onlyOwner{
        owner = _to;
    }

    function Deposit() public payable{
        (bool success, ) = address(this).call{value: msg.value}(""); 
        require (success, "Failed to deposit!!!");
        emit deposit (msg.sender, msg.value);
    }   // in call funciton, since msg.value is used. Tx is from msg.sender to contract.

    receive() external payable{}

    function Withdraw(uint256 _val) public payable onlyOwner nonRentrant{
        require (address(this).balance >= _val*(10**18), "Not enough balance");
        (bool getit, ) = msg.sender.call{value: _val*(10**18)}("");
        require (getit, "Failed to Withdraw");
    }   // in call function, since _val (argument) is used. TX is from Contract to msg.sender.

    function Balanceof() public view onlyOwner returns(uint256){
        return address(this).balance;
    }

    function SubmitTransaction(address _add, uint _value) public
    onlyOwner{
        uint txIndex = Transactions.length;
        Transactions.push (
            transaction(
                _add,
                _value*(10**18),
                false,
                false
        ));
        emit submitTransaction(msg.sender, txIndex, _value*(10**18), _add);
    }

    function ConfirmTransaction(uint _txIndex) public
    onlyOwner
    txExist (_txIndex)
    txNotConfirmed (_txIndex){
        Transactions[_txIndex].txConfirmed = true;
        emit confirmTransaction (msg.sender, _txIndex);
    }

    function ExecuteTransaction(uint _txIndex) public payable
    onlyOwner
    txExist (_txIndex)
    txConfirmed (_txIndex)
    txNotExecuted (_txIndex)
    nonRentrant {
        require (Transactions[_txIndex].value <= address(this).balance, "Not enough balance!!");

        // If you want to use call. No gas limit in call
        (bool exec, ) = Transactions[_txIndex].to.call{value: Transactions[_txIndex].value}("");
        require (exec, "Transaction didn't got executed!!");    

        //If you want to use transfer. There is gas limit in transfer and it throw an exception when fail to execute
        //Transactions[_txIndex].to.transfer(Transactions[_txIndex].value);

        Transactions[_txIndex].txExecuted = true;
        emit executeTransaction (msg.sender, _txIndex);
    }
}