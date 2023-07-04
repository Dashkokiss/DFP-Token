// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

contract HelperConfig {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address usdt;
        address usdtOwner;
        address wallet;
    }

    mapping(uint256 => NetworkConfig) public chainIdToNetworkConfig;

    constructor() {
        chainIdToNetworkConfig[1] = getMainnetConfig(); // mainnet
        chainIdToNetworkConfig[11155111] = getSepoliaConfig(); // sepolia

        activeNetworkConfig = chainIdToNetworkConfig[block.chainid];
    }

    function getMainnetConfig() public pure returns (NetworkConfig memory mainnetNetworkConfig) {
        mainnetNetworkConfig = NetworkConfig({
            usdt: 0xdAC17F958D2ee523a2206206994597C13D831ec7,
            usdtOwner: 0xC6CDE7C39eB2f0F0095F41570af89eFC2C1Ea828,
            wallet: 0x32bb35Fc246CB3979c4Df996F18366C6c753c29c
        });
    }

    function getSepoliaConfig() public pure returns (NetworkConfig memory sepoliaNetworkConfig) {
        sepoliaNetworkConfig = NetworkConfig({
            usdt: 0x7169D38820dfd117C3FA1f22a697dBA58d90BA06,
            usdtOwner: 0xfe80d187f052C18532DfEFD0152647786fb0A7c6,
            wallet: 0x32bb35Fc246CB3979c4Df996F18366C6c753c29c
        });
    }
}
