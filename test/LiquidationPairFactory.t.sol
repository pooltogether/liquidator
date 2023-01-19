// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {UFixed32x9} from "../src/libraries/FixedMathLib.sol";
import {LiquidationPairFactory} from "../src/LiquidationPairFactory.sol";
import {LiquidationPair} from "../src/LiquidationPair.sol";
import {ILiquidationSource} from "../src/interfaces/ILiquidationSource.sol";
import {BaseSetup} from "./utils/BaseSetup.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockLiquidationPairYieldSource} from "./mocks/MockLiquidationPairYieldSource.sol";

contract LiquidationPairFactoryTest is BaseSetup {
    LiquidationPairFactory public factory;
    MockERC20 public tokenIn;
    MockERC20 public tokenOut;
    MockLiquidationPairYieldSource public source;
    address public target = 0x27fcf06DcFFdDB6Ec5F62D466987e863ec6aE6A0;

    event PairCreated(
        LiquidationPair indexed liquidator,
        ILiquidationSource indexed source,
        address target,
        IERC20 indexed tokenIn,
        IERC20 tokenOut,
        UFixed32x9 swapMultiplier,
        UFixed32x9 liquidityFraction,
        uint256 virtualReserveIn,
        uint256 virtualReserveOut
    );

    function setUp() public virtual override {
        super.setUp();
        // Contract setup
        factory = new LiquidationPairFactory();
        tokenIn = new MockERC20("tokenIn", "IN", 18);
        tokenOut = new MockERC20("tokenOut", "OUT", 18);
        source = new MockLiquidationPairYieldSource();
    }

    function testCreatePair() public {
        vm.expectEmit(false, true, true, true);
        emit PairCreated(
            LiquidationPair(0x0000000000000000000000000000000000000000),
            source,
            address(target),
            tokenIn,
            tokenOut,
            UFixed32x9.wrap(300000),
            UFixed32x9.wrap(20000),
            100,
            100
            );
        LiquidationPair lp = factory.createPair(
            address(this), source, target, tokenIn, tokenOut, UFixed32x9.wrap(300000), UFixed32x9.wrap(20000), 100, 100
        );
        assertEq(lp.owner(), address(this));
        assertEq(address(lp.source()), address(source));
        assertEq(lp.target(), address(target));
        assertEq(address(lp.tokenIn()), address(tokenIn));
        assertEq(address(lp.tokenOut()), address(tokenOut));
        assertEq(UFixed32x9.unwrap(lp.swapMultiplier()), 300000);
        assertEq(UFixed32x9.unwrap(lp.liquidityFraction()), 20000);
        assertEq(lp.virtualReserveIn(), 100);
        assertEq(lp.virtualReserveOut(), 100);
    }

    function testCannotCreatePair() public {
        vm.expectRevert(bytes("LiquidationPair/liquidity-fraction-greater-than-zero"));
        factory.createPair(
            address(this), source, target, tokenIn, tokenOut, UFixed32x9.wrap(300000), UFixed32x9.wrap(0), 100, 100
        );
    }
}
