// SPDX-License-Identifier: MIT
pragma solidity 0.8.35;

import { Script, console2 } from 'forge-std/Script.sol';
import { UtexoLZAdapter }   from '../../src/UtexoLZAdapter.sol';

/// @title DeployUtexoLZAdapter
/// @notice Deploys `UtexoLZAdapter` on the destination chain (Arbitrum). The
///         contract is stateless apart from `_stuckFunds` + `trustedEntrypoints`
///         and non-upgradeable — all five wire addresses are immutable. To
///         repoint any of them the adapter must be redeployed and the new
///         address rotated through `MultisigProxy` federation governance on
///         the Bridge side (e.g. via the bridge-smart-contracts admin scripts).
///
/// Env:
///   PRIVATE_KEY              — deployer private key
///   LZ_ENDPOINT_ADDRESS      — LayerZero V2 EndpointV2 on Arbitrum
///   OFT_ADDRESS              — USDT0 OFT on Arbitrum
///   TOKEN_ADDRESS            — USDT0 token on Arbitrum
///   BRIDGE_ADDRESS           — Utexo `Bridge` on Arbitrum
///   MULTISIG_PROXY_ADDRESS   — Utexo `MultisigProxy` on Arbitrum
///
/// Usage:
///   forge script script/deploy/DeployUtexoLZAdapter.s.sol \
///     --rpc-url $RPC_URL --broadcast --verify
///
/// Post-deployment:
///   1. Verify the five immutables logged below match the expected addresses.
///   2. On the Bridge side, set `lzAdapter` to the new address via
///      `MultisigProxy` (until that is done the adapter-only `Bridge.fundsIn`
///      overload reverts `NotLZAdapter`).
///   3. Whitelist source-chain `UtexoSourceEntrypoint` addresses via
///      `setTrustedEntrypoint(bytes32, true)` from `MultisigProxy` — until at
///      least one entrypoint is trusted, every inbound `lzCompose` reverts
///      `UntrustedComposeSource` and the LayerZero compose queue stalls.
contract DeployUtexoLZAdapter is Script {
    function run() external returns (UtexoLZAdapter adapter) {
        uint256 pk             = vm.envUint('PRIVATE_KEY');
        address endpoint       = vm.envAddress('LZ_ENDPOINT_ADDRESS');
        address oft            = vm.envAddress('OFT_ADDRESS');
        address token          = vm.envAddress('TOKEN_ADDRESS');
        address bridge         = vm.envAddress('BRIDGE_ADDRESS');
        address multisigProxy  = vm.envAddress('MULTISIG_PROXY_ADDRESS');

        vm.startBroadcast(pk);
        adapter = new UtexoLZAdapter(endpoint, oft, token, bridge, multisigProxy);
        vm.stopBroadcast();

        console2.log('UtexoLZAdapter deployed at:', address(adapter));
        console2.log('Endpoint:      ', adapter.endpoint());
        console2.log('OFT:           ', adapter.oft());
        console2.log('Token:         ', adapter.token());
        console2.log('Bridge:        ', adapter.bridge());
        console2.log('MultisigProxy: ', adapter.multisigProxy());
    }
}
