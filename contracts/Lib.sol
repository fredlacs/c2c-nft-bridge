//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

struct Commit721 {
    IERC721 token;
    uint256 tokenId;
    address minter;
    uint256 fromChainId;
    uint256 toChainId;
    uint256 nonce;
}

library Lib {
    function getCommitHash(Commit721 calldata commit) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            commit.token, commit.tokenId, commit.minter, commit.fromChainId, commit.toChainId, commit.nonce
        ));
    }

    function chainId() internal view returns (uint256 _chainId) {
        assembly {
            _chainId := chainid()
        }
    }
}
