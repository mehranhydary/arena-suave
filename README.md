# <h1 align="center"> Arena X on SUAVE </h1>

Minimize MEV while using Uniswap's Universal Router on any chain.

## <h2 align="">Authors</h2>

[Mehran Hydary](https://x.com/mehranhydary)

## <h2 align="">Overview</h2>

Arena X on SUAVE is an MEV application where users can submit signed intents for [Uniswap's Universal Router](https://github.com/Uniswap/universal-router) on any chain. Signed intents are shared with searchers/peekers and they're able to backrun the intents with additional transactions.

### <h3 align="">How it works</h3>

<b>Setup</b>

1. The constructor takes 2 inputs, an array of chain ids and an array of builder urls. These inputs will initialize a mapping called `builderUrlsByChainId`. Ensure that the indexes for both inputs correspond (i.e. chainIds[0] should have a builderUrl that is relevant to the id stored at chainIds[0]).
2. TALK ABOUT ONLY OWNER BEING USED TO CONTROL THE MEV APPLICATION (ADDING CHAIN IDS, ETC.)

<b>Sending a transaction with SUAVE</b>

1. Users will create an `Order`. The order includes their signing address, a list of commands they want to perform, the corresponding data, a deadline, and the chain id they want to execute the transaction on.
2. Once they confirm the `Order`, they will sign it and create an `OrderIntent`. This `OrderIntent` will be sent to the Arena X MEV Application on SUAVE through the `newIntent` function. The `OrderIntent` is passed confidentially to SUAVE.
3. In the `newIntent` function, the details of the `Order` will be shared to searchers under the tag `orderIntent`. Searchers can query the `orderIntent` key on SUAVE and read details of the order.
4. If searchers want to fulfil the order, they can call `submitSolution`. This function gets the block number of the chain id specified in the `OrderIntent`. If the block number is the same as when the `OrderIntent` was passed in, then it'll rank the solution with other solutions for this block. If the block number has progressed, the best solution will be submitted on chain (based on the `_rankSolution` function).
5. The `_rankSolution` function compares `egp` and ensures that the order is valid (signature, nonce, etc.) before considering it as a solution.

### <h3 align="">Why Universal Router?</h3>

The Universal Router is an ERC20 and NFT swap router that allows for greater flexibility when tokens are traded. Transactions are encoded using a string of commands so multiple actions and the corresponding data for those actions can be executed on chain as a single transaction.

### <h3 align="">Supported Chains</h3>

Currently, the Uniswap Universal Router is deployed on the following chains:

1. Arbitrum
2. Avalanche
3. Base
4. Binance Smart Chain
5. Celo
6. Mainnet
7. Optimism
8. Polygon

## <h2 align="">Roadmap</h2>

# ADD THIS BEFORE MAKING PUBLIC

-   CUSTOM PRE-COMPILE TO GET BLOCK NUMBERS FROM MULTIPLE CHAINS (BASED ON WHAT IS PASSED IN)
-   FIGURE OUT A BETTER WAY TO RANK THE SOLUTIONS PROVIDED WITHIN A BLOCK
-   ADD AN ADMIN THAT CAN ADD CHAINS AS MORE THINGS GET DEPLOYED

1. Adding support for EIP-712 signatures
2. Adding support for EIP-1271 signatures
3. Adding support for multiple RPCs per chain
4. Build a dApp for users to support Arena X
5. Create searchers that listen to Arena X hints on SUAVE

## <h2 align="">License</h2>

This project is licensed under AGPL-3.0-only.

## <h2 align="">Disclaimer</h2>

This is experimental software and is provided on an "as is" and "as available" basis.
