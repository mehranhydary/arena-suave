// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "suave/SuaveForge.sol";
import "./Structs.sol";

contract Intent {
    event IntentCreated(
        Suave.BidId bidId,
        address indexed maker,
        uint256 nonce,
        uint256 deadline,
        bytes commands,
        bytes[] inputs
    );

    function fetchIntentConfidentialBundleData()
        public
        view
        returns (OrderIntent memory)
    {
        require(Suave.isConfidential());

        bytes memory confidentialInputs = Suave.confidentialInputs();
        return abi.decode(confidentialInputs, (OrderIntent));
    }

    function emitIntent(
        Order memory order,
        Suave.BidId bidId
    ) external payable {
        emit IntentCreated(
            bidId,
            order.maker,
            order.nonce,
            order.deadline,
            order.commands,
            order.inputs
        );
    }
}
