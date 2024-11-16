// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {CreditDefaultSwap} from "../src/CreditDefaultSwap.sol";
import {Script} from "forge-std/Script.sol";

contract DeployCreditDefaultSwap is Script {

    function run() external returns(CreditDefaultSwap) {

        vm.startBroadcast();
        CreditDefaultSwap creditDefaultSwap = new CreditDefaultSwap();
        vm.stopBroadcast();
        return creditDefaultSwap;
    }
}