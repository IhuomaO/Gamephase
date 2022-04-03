// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  // Contract's Modifiers
  /**
  * @notice Modifier that require the deadline to be reached or not
  * @param requireReached Check if the deadline has reached or not
  */
        modifier deadlineReached( bool requireReached ) {
          uint256 timeRemaining = timeLeft();
          if( requireReached ) {
            require(timeRemaining == 0, "Deadline is not reached yet");
          } else {
            require(timeRemaining > 0, "Deadline is already reached");
          }
          _;
        }

  /**
  * @notice Modifier that require the external contract to not be completed
  */
      modifier notCompleted() {
        bool completed = exampleExternalContract.completed();
        require(!completed, "staking process already completed");
        _;
     }

  constructor(address exampleExternalContractAddress) public {
       exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
       // Balances of the user's stacked funds
        mapping(address => uint256) public balances;

      // Staking threshold
        uint256 public constant threshold = 1 ether;

      // Staking deadline
        uint256 public deadline = block.timestamp + 72 hours;

      // Contract's Events
        event Stake(address indexed sender, uint256 amount);

  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
       function stake() public payable deadlineReached(false) notCompleted {
          // update the user's balance
          balances[msg.sender] += msg.value;
          
          // emit the event to notify the blockchain that we have correctly Staked some fund for the user
          emit Stake(msg.sender, msg.value);
        }

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
        function execute() public notCompleted deadlineReached(false) {
          uint256 contractBalance = address(this).balance;

          // check the contract has enough ETH to reach the treshold
          require(contractBalance >= threshold, "Threshold not reached");

          // Execute the external contract, transfer all the balance to the contract
          // (bool sent, bytes memory data) = exampleExternalContract.complete{value: contractBalance}();
          (bool sent,) = address(exampleExternalContract).call{value: contractBalance}(abi.encodeWithSignature("complete()"));
          require(sent, "exampleExternalContract.complete failed");
        }

  // if the `threshold` was not met, allow everyone to call a `withdraw()` function
  // Add a `withdraw()` function to let users withdraw their balance
        function withdraw() public deadlineReached(true)  notCompleted {
          uint256 userBalance = balances[msg.sender];

          // check if the user has balance to withdraw
          require(userBalance > 0, "You don't have balance to withdraw");

          // reset the balance of the user
          balances[msg.sender] = 0;

          // Transfer balance back to the user
          (bool sent,) = msg.sender.call{value: userBalance}("");
          require(sent, "Failed to send user balance back to the user");
        }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
        function timeLeft() public view returns (uint256 timeleft) {
          if( block.timestamp >= deadline ) {
            return 0;
          } else {
            return deadline - block.timestamp;
          }
        }

  // Add the `receive()` special function that receives eth and calls stake()
        receive() external payable {
          stake();
    }

}
