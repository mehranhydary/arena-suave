// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {SignatureVerification} from "./SignatureVerification.sol";
import {OrderIntent} from "../base/Structs.sol";

library OrderIntentLibrary {
    using SignatureVerification for OrderIntent;

    error DeadlinePassed();

    // error InvalidNonce();
    // error InvalidOrder();

    function validate(OrderIntent memory orderIntent) internal view {
        if (orderIntent.order.deadline < block.timestamp) {
            revert DeadlinePassed();
        }

        // Figure out how to check nonce later (maybe can't do it here)
        orderIntent.verify();
    }
}
