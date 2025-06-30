// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SafeServiceEscrow is AccessControl, ReentrancyGuard {
    bytes32 public constant CLIENT_ROLE = keccak256("CLIENT_ROLE");
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");

    enum Status { Active, Completed, Refunded, Disputed }

    address payable public agent;
    address payable public client;
    uint256 public deadline;
    uint256 public amount;
    Status public status;

    event ServiceConfirmed(address indexed by, uint256 amount);
    event Refunded(address indexed to, uint256 amount);
    event DisputeRaised(address indexed by);

    modifier onlyClient() {
        require(hasRole(CLIENT_ROLE, msg.sender), "Not client");
        _;
    }

    modifier onlyAgent() {
        require(hasRole(AGENT_ROLE, msg.sender), "Not agent");
        _;
    }

    constructor(address payable _client, address payable _agent, uint256 _duration) payable {
        require(msg.value > 0, "Escrow must be funded");

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CLIENT_ROLE, _client);
        _grantRole(AGENT_ROLE, _agent);

        client = _client;
        agent = _agent;
        deadline = block.timestamp + _duration;
        amount = msg.value;
        status = Status.Active;
    }

    function confirmCompletion() external onlyClient nonReentrant {
        require(status == Status.Active, "Invalid status");
        require(block.timestamp <= deadline, "Past deadline");

        status = Status.Completed;
        (bool success, ) = agent.call{value: amount}("");
        require(success, "Payment failed");

        emit ServiceConfirmed(msg.sender, amount);
    }

    function cancelAndRefund() external onlyClient nonReentrant {
        require(status == Status.Active, "Invalid status");
        require(block.timestamp > deadline, "Deadline not passed");

        status = Status.Refunded;
        (bool success, ) = client.call{value: amount}("");
        require(success, "Refund failed");

        emit Refunded(client, amount);
    }

    function raiseDispute() external onlyClient {
        require(status == Status.Active, "Cannot dispute now");
        status = Status.Disputed;
        emit DisputeRaised(msg.sender);
    }

    function getStatus() external view returns (string memory) {
        if (status == Status.Active) return "Active";
        if (status == Status.Completed) return "Completed";
        if (status == Status.Refunded) return "Refunded";
        if (status == Status.Disputed) return "Disputed";
        return "Unknown";
    }
}
