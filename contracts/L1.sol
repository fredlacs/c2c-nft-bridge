//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Lib.sol";
import "./Claim721.sol";

import "@openzeppelin/contracts/utils/Create2.sol";

interface IL1 {
    function claimEscrow(Commit721 calldata commit, address claimTo) external;
}

error NotL2Counterpart();
error IncorrectChainId();
error OldNonce();

contract L1 is IL1 {
    address immutable public l2Counterpart;
    bytes32 immutable public escrowBytecodeHash;
    uint256 immutable private chainId;

    // toChainId => commit.token => commit.tokenId
    mapping(uint256 => mapping(IERC721 => mapping(uint256 => uint256))) public nonce;
    
    constructor(address l2C2C) {
        l2Counterpart = l2C2C;
        escrowBytecodeHash = keccak256(type(Claim721).creationCode);
        chainId = Lib.chainId();
    }

    function calledByl2Counterpart() internal virtual view returns (bool) {
        return msg.sender == l2Counterpart;
    }
    
    function getEscrowAddress(bytes32 commitHash) external view returns (address) {
        return Create2.computeAddress(commitHash, escrowBytecodeHash, address(this));
    }

    function claimEscrow(
        Commit721 calldata commit,
        address claimTo
    ) external override {
        if(!calledByl2Counterpart()) revert NotL2Counterpart();
        if(commit.fromChainId != chainId) revert IncorrectChainId();
        if(
            commit.nonce < nonce[commit.toChainId][commit.token][commit.tokenId]
        ) revert OldNonce();

        bytes32 commitHash = Lib.getCommitHash(commit);
        nonce[commit.toChainId][commit.token][commit.tokenId] = commit.nonce + 1;
        // we expect this step to revert if the NFT is not held in escrow
        new Claim721{ salt: commitHash }(commit.token, commit.tokenId, claimTo);
    }
}
