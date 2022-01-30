//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Lib.sol";
import "./Claim721.sol";

import "@openzeppelin/contracts/utils/Create2.sol";

interface IL1 {
    function claimEscrow(Commit721 calldata commit, address claimTo) external;
}

contract L1 is IL1 {
    address immutable public l2Counterpart;
    bytes32 immutable public escrowBytecodeHash;
    uint256 immutable private chainId;

    // nonce[commit.toChainId][commit.token][commit.tokenId]
    mapping(uint256 => mapping(IERC721 => mapping(uint256 => uint256))) public nonce;
    
    constructor(address l2C2C) {
        l2Counterpart = l2C2C;
        escrowBytecodeHash = keccak256(type(Claim721).creationCode);
        chainId = Lib.chainId();
    }

    function calledByl2Counterpart() internal virtual view returns (bool) {
        return msg.sender == l2Counterpart;
    }
    
    function getEscrowAddress(bytes32 commitHash) public view returns (address) {
        return Create2.computeAddress(commitHash, escrowBytecodeHash, address(this));
    }

    function claimEscrow(
        Commit721 calldata commit,
        address claimTo
    ) external override {
        require(calledByl2Counterpart(), "NOT_FROM_L2");
        require(commit.fromChainId == chainId, "WRONG_CHAIN_CLAIM");
        // TODO: not sure how this should behave if network gets forked
        bytes32 commitHash = Lib.getCommitHash(commit);
        address escrow = getEscrowAddress(commitHash);
        address expectedOwner = commit.token.ownerOf(commit.tokenId);
        require(escrow == expectedOwner, "ESCROW_NOT_OWNER");
        // TODO: is there a race condition here?
        // TODO: nonce logic to settle a domain in O(1) messages
        require(commit.nonce > nonce[commit.toChainId][commit.token][commit.tokenId], "NEED_NEW_NONCE");
        nonce[commit.toChainId][commit.token][commit.tokenId] = commit.nonce;
        new Claim721{ salt: commitHash }(commit.token, commit.tokenId, claimTo);
    }
}
