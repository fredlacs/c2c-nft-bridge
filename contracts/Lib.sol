//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { Commit721 } from "./IClaimer.sol";

library Lib {
    function getCommitHash(Commit721 calldata commit) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            commit.token, commit.tokenId, commit.minterUser, commit.fromChainId, commit.toChainId, commit.nonce
        ));
    }
}
