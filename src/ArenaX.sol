// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Intent} from "./base/Intent.sol";
import "suave/SuaveForge.sol";
import {OrderIntent, OrderSolutionResult, Network} from "./base/Structs.sol";
import {OrderIntentLibrary} from "./libraries/OrderIntentLibrary.sol";

// Make this multi-chain!
// Figure out what chains have the Universal Router
// Figure out how you're gonna store rpcs + chains (maybe with a Network struct)
// Figure out how you're gonna update the structs so that chain id is reflected (see
// if that impacts the signatures at all (should because we should enforce EIP-712 signatures))
contract ArenaX is Intent {
    using OrderIntentLibrary for OrderIntent;

    string[] public builderUrls;
    uint64 latestExternalBlock;
    mapping(uint64 blockNumber => OrderSolutionResult) public topRankedSolution;

    event BlockNumberUpdated(uint64 blockNumber);

    constructor(string[] memory builderUrls_) {
        builderUrls = builderUrls_;
    }

    // Related to receiving
    function newOrder() external payable returns (bytes memory) {
        require(Suave.isConfidential());

        OrderIntent memory orderIntent = this
            .fetchIntentConfidentialBundleData();

        address[] memory allowedList = new address[](1);
        allowedList[0] = address(this);
        Suave.Bid memory bid = Suave.newBid(
            10,
            allowedList,
            allowedList,
            "orderIntent"
        );

        Suave.confidentialStore(bid.id, "orderIntent", abi.encode(orderIntent));

        return
            abi.encodeWithSelector(
                this.emitIntent.selector,
                orderIntent.order,
                bid.id
            );
    }

    // Related to sending
    function submitSolution(
        Suave.BidId orderBidId
    ) external payable returns (bytes memory) {
        require(Suave.isConfidential());
        uint64 previousBlockNumber = latestExternalBlock;

        updateExternalBlockNumber();

        if (latestExternalBlock > previousBlockNumber) {
            Suave.BidId topSolutionBidId = topRankedSolution[
                previousBlockNumber
            ].bidId;
            bytes memory bundleData = Suave.fillMevShareBundle(
                topSolutionBidId
            );
            for (uint i = 0; i < builderUrls.length; i++) {
                Suave.submitBundleJsonRPC(
                    builderUrls[i],
                    "mev_sendBundle",
                    bundleData
                );
            }
        }

        _rankSolution(orderBidId);
        return abi.encodeWithSelector(this.emptyCallback.selector);
    }

    function updateExternalBlockNumber() public view returns (bytes memory) {
        uint64 blockNumber = Suave.getBlockNumber();
        return
            abi.encodeWithSelector(this.setBlockNumber.selector, blockNumber);
    }

    function setBlockNumber(uint64 blockNumber) public {
        latestExternalBlock = blockNumber;
        emit BlockNumberUpdated(blockNumber);
    }

    function emptyCallback() external payable {}

    function _rankSolution(Suave.BidId orderBidId) internal {
        // This is new (not related to the order intent; this has the
        // backrun transactions as well)
        bytes memory bundleData = Suave.confidentialInputs();
        uint64 egp = Suave.simulateBundle(bundleData);

        bytes memory intentData = Suave.confidentialRetrieve(
            orderBidId,
            "orderIntent"
        );
        OrderIntent memory orderIntent = abi.decode(intentData, (OrderIntent));

        // Add order intent validation
        orderIntent.validate();

        OrderSolutionResult memory currentTopSolution = topRankedSolution[
            latestExternalBlock
        ];

        if (egp > currentTopSolution.score) {
            address[] memory allowedList = new address[](1);
            allowedList[0] = address(this);
            Suave.Bid memory bid = Suave.newBid(
                10,
                allowedList,
                allowedList,
                ""
            );
            Suave.confidentialStore(
                bid.id,
                "orderSolutionResult",
                abi.encode(
                    OrderSolutionResult({
                        solver: msg.sender,
                        score: egp,
                        bidId: orderBidId
                    })
                )
            );
            topRankedSolution[latestExternalBlock] = OrderSolutionResult({
                solver: msg.sender,
                score: egp,
                bidId: orderBidId
            });
        }
    }
}
