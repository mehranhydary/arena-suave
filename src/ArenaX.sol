// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "suave/SuaveForge.sol";
import {Intent} from "./base/Intent.sol";
import {OrderIntent, OrderSolutionResult, Network} from "./base/Structs.sol";
import {OrderIntentLibrary} from "./libraries/OrderIntentLibrary.sol";

contract ArenaX is Intent {
    error InvalidInput();
    error InvalidChain(string);
    using OrderIntentLibrary for OrderIntent;

    mapping(string => string) public builderUrlsByChainId;
    mapping(string => uint64) public latestExternalBlock;
    mapping(uint64 blockNumber => OrderSolutionResult) public topRankedSolution;

    event BlockNumberUpdated(string chainId, uint64 blockNumber);

    constructor(string[] memory chainIds, string[] memory builderUrls) {
        if (chainIds.length != builderUrls.length) {
            revert InvalidInput();
        }
        for (uint i = 0; i < chainIds.length; i++) {
            builderUrlsByChainId[chainIds[i]] = builderUrls[i];
        }
    }

    // Related to receiving
    function newIntent() external payable returns (bytes memory) {
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
        bytes memory intentData = Suave.confidentialRetrieve(
            orderBidId,
            "orderIntent"
        );
        OrderIntent memory orderIntent = abi.decode(intentData, (OrderIntent));
        string memory chainId = orderIntent.order.chainId;
        uint64 previousBlockNumber = latestExternalBlock[chainId];

        updateExternalBlockNumber(chainId);

        if (latestExternalBlock[chainId] > previousBlockNumber) {
            Suave.BidId topSolutionBidId = topRankedSolution[
                previousBlockNumber
            ].bidId;
            bytes memory bundleData = Suave.fillMevShareBundle(
                topSolutionBidId
            );
            string memory builderUrl = builderUrlsByChainId[chainId];

            if (!(bytes(builderUrl).length > 0)) {
                revert InvalidChain(chainId);
            }

            Suave.submitBundleJsonRPC(builderUrl, "mev_sendBundle", bundleData);
        }

        _rankSolution(orderBidId);
        return abi.encodeWithSelector(this.emptyCallback.selector);
    }

    function updateExternalBlockNumber(
        string memory chainId
    ) public view returns (bytes memory) {
        // Need to update this so that it takes in a chain id
        uint64 blockNumber = Suave.getBlockNumber(
            builderUrlsByChainId[chainId]
        );
        return
            abi.encodeWithSelector(
                this.setBlockNumber.selector,
                chainId,
                blockNumber
            );
    }

    function setBlockNumber(string memory chainId, uint64 blockNumber) public {
        latestExternalBlock[chainId] = blockNumber;
        emit BlockNumberUpdated(chainId, blockNumber);
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
            latestExternalBlock[orderIntent.order.chainId]
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
            topRankedSolution[
                latestExternalBlock[orderIntent.order.chainId]
            ] = OrderSolutionResult({
                solver: msg.sender,
                score: egp,
                bidId: orderBidId
            });
        }
    }
}
