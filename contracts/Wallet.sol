//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./ERC20/ERC20.sol";

//Single Owner Wallet
contract EKWallet{

    event deposit(address indexed sender, address tokenAddress, uint amount);
    event balanceof(address indexed tokenaddress, uint amount);
    event withdraw(address indexed receiver, address tokenAddress, uint amount);
    event submitTransaction(address indexed sender, address tokenaddress, uint txIndex, uint amount, address to);
    event confirmTransaction(address indexed owner, uint txIndex);
    event executeTransaction(address indexed owner, uint txIndex);

    address private owner;

    mapping (address => uint256) private TokenBalance;

    struct transaction{
        address token;
        address payable to;
        uint value;
        bool txConfirmed;
        bool txExecuted;
    }

    transaction[] private Transactions;
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

    function OwnerAddress() public view onlyOwner returns(address){
        return(owner);
    }

    function TransferOwnership(address _to) public onlyOwner{
        owner = _to;
    }

    function ViewTransaction(uint256 _no) public view onlyOwner returns(transaction memory){
        return(Transactions[_no]);
    }

    function Deposit(address _tokenAddress, uint _val) public payable{
        if (_tokenAddress == address(0)){
            require (msg.value == _val, "Incorrect amount in msg.value");
            (bool success, ) = address(this).call{value: msg.value}(""); 
            // in call funciton, since msg.value is used. Tx is from msg.sender to contract.
            require(success, "Failed to deposit Eth.");
        }else{
            ERC20 token = ERC20(_tokenAddress);
            require (token.allowance(msg.sender, address(this)) >= _val, "Insufficient Allowance!!!");
            // Allowance is ERC20 function to check if receiver is allowed by sender to use the token.
            bool success = token.transferFrom(msg.sender, address(this), _val);
            require (success, "Failed to deposit!!!");
        }
        TokenBalance[_tokenAddress] += _val;
        emit deposit (msg.sender, _tokenAddress, _val);
    }   

    receive() external payable{}

    // if a new ERC20 token have been sent to the wallet contract, then token needs to be mapped to get balance.
    function MapToken(address _tokenAddress) public onlyOwner{
        if (_tokenAddress == address(0)){
            TokenBalance[_tokenAddress] = address(this).balance;
        }else{
            ERC20 token = ERC20(_tokenAddress);
            uint256 bal = token.balanceOf(address(this)); // using ERC20 contract balanceof().
            TokenBalance[_tokenAddress] = bal;
        }
    }

    function Withdraw(address _tokenAddress, uint256 _val) public payable onlyOwner nonRentrant{
        require (TokenBalance[_tokenAddress] >= _val, "Not enough balance");
        ERC20 token = ERC20(_tokenAddress);
        (bool getit ) = token.transfer(msg.sender, _val);
        require (getit, "Failed to Withdraw");
        TokenBalance[_tokenAddress]-=_val;
        emit withdraw(msg.sender, _tokenAddress, _val);
    }   // in call function, since _val (argument) is used. TX is from Contract to msg.sender.

    function Balanceof(address _tokenAddress) public onlyOwner returns(uint256){
        emit balanceof(_tokenAddress, TokenBalance[_tokenAddress]);
        return TokenBalance[_tokenAddress];
    }

    function SubmitTransaction(address _tokenaddress, address payable _add, uint _value) external
    onlyOwner{
        uint txIndex = Transactions.length;
        Transactions.push (
            transaction(
                _tokenaddress,
                _add,
                _value*(10**18),
                false,
                false
        ));
        emit submitTransaction(msg.sender, _tokenaddress, txIndex, _value*(10**18), _add);
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
        ERC20 token = ERC20(Transactions[_txIndex].token);
        uint _txVal = Transactions[_txIndex].value;
        require (_txVal <= TokenBalance[Transactions[_txIndex].token], "Not enough balance!!");
        bool success = token.transferFrom(address(this), Transactions[_txIndex].to, _txVal);
        require (success, "TX failed to Execute");

        // If you want to use call. No gas limit in call
        // (bool exec, ) = Transactions[_txIndex].to.call{value: Transactions[_txIndex].value}("");
        // require (exec, "Transaction didn't got executed!!");    
        //If you want to use transfer. There is gas limit in transfer and it throw an exception when fail to execute
        //Transactions[_txIndex].to.transfer(Transactions[_txIndex].value);

        TokenBalance[Transactions[_txIndex].token] -= _txVal;
        Transactions[_txIndex].txExecuted = true;
        emit executeTransaction (msg.sender, _txIndex);
    }
}
