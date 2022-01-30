//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

struct Commit721 {
    IERC721 token;
    uint256 tokenId;
    address minterUser;
    uint256 fromChainId;
    uint256 toChainId;
    uint256 nonce;
}

interface IClaimer {
    function claimEscrow(Commit721 calldata commit, address claimTo) external;
}
