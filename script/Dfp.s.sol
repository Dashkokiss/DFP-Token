// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {DFP} from "src/Dfp.sol";

contract DeployDfp is Script {
    DFP internal dfp;
    address internal usdt;
    address internal wallet;

    function run() external {
        HelperConfig helperConfig = new HelperConfig();

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (usdt,, wallet) = helperConfig.activeNetworkConfig();

        dfp = new DFP(IERC20(usdt), wallet);

        console.log("Chin id : ", block.chainid);
        console.log("DFP address : ", address(dfp));
        console.log("USDT address : ", address(usdt));
        console.log("Wallet address : ", wallet);

        vm.stopBroadcast();
    }
}
