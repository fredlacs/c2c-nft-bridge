# C2C NFT Bridge

```
Create2 Counterfactual NFT Bridge

the idea here is that you can get a NFT bridge that doesn't need to send a L1 to L2 tx. you instead make one L1 tx and one L2 tx. 
For that the user would transfer their nft token to a predetermined address in the L1. as minimal as L1 interactions can be.
Then on the L2 they would deploy a nft through a trusted factory contract. Deploy would be a NFT that commits to a user deploying a certain token address and id.
For a withdrawal the trusted factory burns (or escrows somewhere) the L2 token. When this happens, the bridge then sends a L2 to L1 tx to a trusted factory in the L1. Now here is the trick of the predetermined address: it can be the result of a create2 from the L1 factory. you can verify the original msg.sender and token info from the original commitment as a salt to the create2. So the escrow contract only gets deployed during the withdrawal so it can send back the token.
```

Only requires one way communication.
Cheapest deposits in town.

Remaps tokenId and assumes offchain verification for validity.
Metadata only available in origin chain.
Allows for fast exits of NFTs
Can support multiple domains (ie transfer from arbitrum to optimism)


Open questions:
 - Can nonce management be built in a way to allow domains to settle in O(1)?
 - How to manage airdrops in previous wrappers? You can just bridge them over too
 - Using create3 on escrow creation would allow for user defined logic when releasing escrow. Is that safe? Might need to add an explicit `token.ownerOf` check
 - Is there a better way of mapping token IDs?
 - Is there a more calldata efficient way of verifying during withdrawal time?
 - Is the self destruct at the end of the escrow release safe?
 - Handle chainId changed if network gets forked?
 - Is there a weird withdrawal race condition? I don't think so.
 - Can we allow withdrawals to optimise for either calldata/storage? Allow users to interact with both modes
