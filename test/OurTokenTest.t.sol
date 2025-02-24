// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployOurToken} from "script/DeployOurToken.s.sol";
import {OurToken} from "src/OurToken.sol";

contract OurTokenTest is Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");

    uint256 public constant STARTING_BALANCE = 100 ether;
    uint256 public constant INITIAL_SUPPLY = 1000 ether;

    function setUp() external {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        vm.prank(msg.sender);
        ourToken.transfer(bob, STARTING_BALANCE);
    }

    function testBobBalance() public view {
        assertEq(STARTING_BALANCE, ourToken.balanceOf(bob));
    }

    function testAllowancesWork() public {
        uint256 initialAllowance = 1000;

        // Bob approves Alice to spend tokens on her behalf
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        uint256 transferAmount = 500;

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);
        /** @notice transfer() is same as transferFrom(), sender = from */
        //  ourToken.transferFrom(bob, alice, transferAmount);

        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
    }

    function testRevertsWhenInsufficientAllowance() public {
        uint256 smallAllowance = 100;

        vm.prank(bob);
        ourToken.approve(alice, smallAllowance);

        vm.prank(alice);
        vm.expectRevert();
        ourToken.transferFrom(bob, alice, smallAllowance + 1);
    }

    // Transfer tests
    function testBasicTransfer() public {
        uint256 transferAmount = 50 ether;

        vm.prank(bob);
        ourToken.transfer(alice, transferAmount);

        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
        assertEq(ourToken.balanceOf(alice), transferAmount);
    }

    function testRevertsWhenTransferInsufficientBalance() public {
        uint256 excessiveAmount = STARTING_BALANCE + 1 ether;

        vm.prank(bob);
        vm.expectRevert();
        ourToken.transfer(alice, excessiveAmount);
    }

    // Additional important tests
    function testInitialSupply() public view {
        assertEq(ourToken.totalSupply(), INITIAL_SUPPLY);
    }

    function testZeroAddressTransferFails() public {
        vm.prank(bob);
        vm.expectRevert();
        ourToken.transfer(address(0), 1 ether);
    }

    function testZeroAddressTransferFromFails() public {
        vm.prank(bob);
        ourToken.approve(alice, 1000);

        vm.prank(alice);
        vm.expectRevert();
        ourToken.transferFrom(bob, address(0), 500);
    }

    function testSelfTransfer() public {
        uint256 initialBalance = ourToken.balanceOf(bob);
        uint256 amount = 1 ether;

        vm.prank(bob);
        ourToken.transfer(bob, amount);

        assertEq(ourToken.balanceOf(bob), initialBalance);
    }

    function testMultipleApprovals() public {
        uint256 firstApproval = 1000;
        uint256 secondApproval = 500;

        vm.prank(bob);
        ourToken.approve(alice, firstApproval);
        assertEq(ourToken.allowance(bob, alice), firstApproval);

        vm.prank(bob);
        ourToken.approve(alice, secondApproval);
        assertEq(ourToken.allowance(bob, alice), secondApproval);
    }

    function testTransferFromZeroAllowance() public {
        vm.prank(alice);
        vm.expectRevert();
        ourToken.transferFrom(bob, alice, 1);
    }
}
