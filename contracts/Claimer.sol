//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Lib.sol";
import "./Escrow721.sol";
import "./IClaimer.sol";

import "@openzeppelin/contracts/utils/Create2.sol";

error NotMinter();
error IncorrectChainId();
error OldNonce();

contract Claimer is IClaimer {
    address immutable public minter;
    bytes32 immutable public escrowBytecodeHash;
    uint256 immutable private chainId;

    // toChainId => commit.token => commit.tokenId
    mapping(uint256 => mapping(IERC721 => mapping(uint256 => uint256))) public nonce;
    
    constructor(address _minter) {
        minter = _minter;
        escrowBytecodeHash = keccak256(type(Escrow721).creationCode);
        chainId = Lib.chainId();
    }

    function calledByMinter() internal virtual view returns (bool) {
        return msg.sender == minter;
    }
    
    function getEscrowAddress(bytes32 commitHash) external view returns (address) {
        return Create2.computeAddress(commitHash, escrowBytecodeHash, address(this));
    }

    function claimEscrow(
        Commit721 calldata commit,
        address claimTo
    ) external override {
        if(!calledByMinter()) revert NotMinter();
        if(commit.fromChainId != chainId) revert IncorrectChainId();
        if(
            commit.nonce < nonce[commit.toChainId][commit.token][commit.tokenId]
        ) revert OldNonce();

        bytes32 commitHash = Lib.getCommitHash(commit);
        nonce[commit.toChainId][commit.token][commit.tokenId] = commit.nonce + 1;
        // we expect this step to revert if the NFT is not held in escrow
        new Escrow721{ salt: commitHash }(commit.token, commit.tokenId, claimTo);
    }
}