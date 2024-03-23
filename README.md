# Experiences

Just learned this Aptos Smart contract, and I think it's more difficult compared to other networks like StarkNet using Cairo, or Substrate using Rust with their Ink framework.

The most confusing aspect is the new architecture, with objects and addresses as main resources that can have multiple contracts, while also needing to learn a new language.

And since I need to develop the game and balance the energy, and we are in a hackathon with strict deadlines, I cannot waste progress on smart contracts alone, as I still need to tweak game mechanics and updates too.

In the end, I was only able to finalize the basic features, but this is my first goal. I just want to develop easier, and then.

So compared to the main smart contract using Solidity, the crafting, the staking feature, the Aptos smart contract is still miles away from reaching that progress. I made some experimental adjustments, but I only submitted what's done and implemented.

# The basic smart contract consists of:

- NFT starship
- NFT asset (materials, season pass, utility, that has no tier)
- Manager store: mainly for accepting other collections and can sell them. But I had a wrong implementation with the "friend" system; this will only integrate with specific addresses instead of dynamically accepting the allowed address regardless of the smart contract structure.

Undeveloped yet on Aptos:

- Play contract: will drop NFT from Pool manager and intervally using an oracle.
- NFT staking: using the reward emission from Theras tokenomics
- Pool manager: creator can submit collection into pool
- Crafting system
- The swap custody protocol

TBC more explaination
