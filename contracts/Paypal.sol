// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Paypal is Ownable {
    struct paymentRequest {
        address generator;
        uint256 amount;
        string name;
        string message;
    }

    struct transaction {
        string action;
        uint256 amount;
        string message;
        address otherPartyAddress;
        string otherPartyName;
    }

    struct userName {
        string name;
        bool hasName;
    }

    mapping(address => userName) names;
    mapping(address => paymentRequest[]) paymentRequests;
    mapping(address => transaction[]) transactionHistory;

    /*-----------------------Contract Functions------------------------------------- */

    /// @notice Add username to a wallet
    /// @param _name new usename of wallet
    function addNameToWallet(string memory _name) public {
        userName storage newUser = names[msg.sender];
        newUser.name = _name;
        newUser.hasName = true;
    }

    /// @notice Create a new payment request
    /// @dev   Pass amount parameter after multiplying with 1e10. This will help with decimal inputs
    /// @param _requestTo Address of the user to request payment
    /// @param _message message added to payment
    /// @param _amount Requested Amount
    function createPaymentRequest(
        address _requestTo,
        string memory _message,
        uint256 _amount
    ) public {
        paymentRequest memory newRequest;

        newRequest.generator = msg.sender;
        newRequest.amount = _amount;
        newRequest.message = _message;

        if (names[msg.sender].hasName) {
            newRequest.name = names[msg.sender].name;
        }

        paymentRequests[_requestTo].push(newRequest);
    }

    /// @notice Complete the payment request by paying native currency
    /// @param _request request index
    function completePaymentRequest(uint256 _request) public payable {
        require(
            _request < paymentRequests[msg.sender].length,
            "Invalid request"
        );
        paymentRequest[] storage myRequests = paymentRequests[msg.sender];
        paymentRequest storage myRequest = myRequests[_request];

        uint256 payAmount = (myRequest.amount * 1e18) / 1e10; // For decimal values

        (bool success, ) = payable(myRequest.generator).call{value: payAmount}(
            ""
        );
        require(success, "Request cannot be fullfilled");

        addTransactionHistory(
            msg.sender,
            myRequest.generator,
            myRequest.amount,
            myRequest.message
        );

        myRequests[_request] = myRequests[myRequests.length - 1];
        myRequests.pop();
    }

    /// @notice Add Transaction history on each send and receive of payment
    /// @param _sender payment sender address
    /// @param _receiver payment receiver address
    /// @param _amount payment amount
    /// @param _message message associated with payment
    function addTransactionHistory(
        address _sender,
        address _receiver,
        uint256 _amount,
        string memory _message
    ) private {
        transaction memory sendPayment;
        sendPayment.action = "-";
        sendPayment.amount = _amount;
        sendPayment.message = _message;
        sendPayment.otherPartyAddress = _receiver;
        if (names[_receiver].hasName) {
            sendPayment.otherPartyName = names[_receiver].name;
        }

        transactionHistory[_sender].push(sendPayment);

        transaction memory receivePayment;
        receivePayment.action = "+";
        receivePayment.amount = _amount;
        receivePayment.message = _message;
        receivePayment.otherPartyAddress = _sender;
        if (names[_sender].hasName) {
            receivePayment.otherPartyName = names[_sender].name;
        }

        transactionHistory[_receiver].push(receivePayment);
    }

    /// @notice Get all user requests
    /// @param _user Address of the user
    /// @return Address,Payment ,Message and Name of the array
    function getUserRequests(
        address _user
    )
        public
        view
        returns (
            address[] memory,
            uint256[] memory,
            string[] memory,
            string[] memory
        )
    {
        address[] memory addressArr = new address[](
            paymentRequests[_user].length
        );
        uint256[] memory amountArr = new uint256[](
            paymentRequests[_user].length
        );
        string[] memory messsageArr = new string[](
            paymentRequests[_user].length
        );
        string[] memory nameArr = new string[](paymentRequests[_user].length);

        for (uint i = 0; i < paymentRequests[_user].length; i++) {
            paymentRequest storage userRequests = paymentRequests[_user][i];
            addressArr[i] = userRequests.generator;
            amountArr[i] = userRequests.amount;
            messsageArr[i] = userRequests.message;
            nameArr[i] = userRequests.name;
        }

        return (addressArr, amountArr, messsageArr, nameArr);
    }

    /// @notice Explain to an end user what this does
    /// @param _user Address of the user
    /// @return
    function getUserHistory(
        address _user
    ) public view returns (transaction[] memory) {
        return transactionHistory[_user];
    }

    /// @notice Get the name associated with account address
    /// @param _user user account address
    /// @return name (if any)
    function getUserName(address _user) public view returns (userName memory) {
        return names[_user];
    }
}
