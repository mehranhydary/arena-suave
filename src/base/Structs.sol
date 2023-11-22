// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "suave/SuaveForge.sol";

struct Order {
    address maker;
    uint256 nonce;
    uint256 deadline;
    bytes commands;
    bytes[] inputs;
    // Note: This is only used on Arena X on SUAVE (not on the Universal Router)
    string chainId;
}

struct OrderIntent {
    Order order;
    bytes signature;
}

struct OrderSolutionResult {
    address solver;
    uint64 score; // egp score
    Suave.BidId bidId;
}

/** Note: Might need these later */

struct EIP712Domain {
    string name;
    string version;
    address verifyingContract;
}

struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

struct Network {
    string name;
    string rpc;
    string chainId;
}
