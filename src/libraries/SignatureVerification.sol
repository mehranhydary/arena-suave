// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Signature, OrderIntent} from "../base/Structs.sol";

// Note: Later on, add EIP-1271 signature support

library SignatureVerification {
    error InvalidSignatureLength();
    error InvalidSignature();
    error InvalidSigner();

    // Look here: https://solidity-by-example.org/signature/
    function verify(OrderIntent memory orderIntent) public pure returns (bool) {
        if (orderIntent.signature.length != 65) {
            revert InvalidSignatureLength();
        }

        Signature memory sig = abi.decode(orderIntent.signature, (Signature));
        bytes memory combinedHashes;
        for (uint i = 0; i < orderIntent.order.inputs.length; i++) {
            combinedHashes = abi.encodePacked(
                combinedHashes,
                keccak256(orderIntent.order.inputs[i])
            );
        }
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(
                        orderIntent.order.maker,
                        orderIntent.order.nonce,
                        orderIntent.order.deadline,
                        orderIntent.order.commands,
                        combinedHashes
                    )
                )
            )
        );

        address recoveredAddress = ecrecover(messageHash, sig.v, sig.r, sig.s);

        if (recoveredAddress != orderIntent.order.maker) {
            revert InvalidSigner();
        }

        return true;
    }
}
