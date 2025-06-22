// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    function setUp() public {
        counter = new Counter();
    }

    function testInitialNumber() public {
        assertEq(counter.number(), 0);
    }

    function testSetNumber() public {
        counter.setNumber(42);
        assertEq(counter.number(), 42);
    }

    function testSetNumberMultipleTimes() public {
        counter.setNumber(10);
        assertEq(counter.number(), 10);
        
        counter.setNumber(20);
        assertEq(counter.number(), 20);
        
        counter.setNumber(0);
        assertEq(counter.number(), 0);
    }

    function testIncrement() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function testIncrementMultipleTimes() public {
        counter.increment();
        counter.increment();
        counter.increment();
        assertEq(counter.number(), 3);
    }

    function testSetNumberThenIncrement() public {
        counter.setNumber(100);
        counter.increment();
        assertEq(counter.number(), 101);
    }

    function testIncrementThenSetNumber() public {
        counter.increment();
        counter.increment();
        assertEq(counter.number(), 2);
        
        counter.setNumber(50);
        assertEq(counter.number(), 50);
    }

    function testFuzzSetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }

    function testFuzzIncrement(uint8 times) public {
        for (uint8 i = 0; i < times; i++) {
            counter.increment();
        }
        assertEq(counter.number(), times);
    }

    function testMaxUint256() public {
        counter.setNumber(type(uint256).max);
        assertEq(counter.number(), type(uint256).max);
    }
}