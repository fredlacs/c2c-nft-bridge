//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Lib.sol";
import "./Escrow721.sol";
import "./IClaimer.sol";

import "@openzeppelin/contracts/utils/Create2.sol";

error NotMinter();
error IncorrectChainId();

contract Claimer is IClaimer {
    address immutable public minter;
    bytes32 immutable public escrowBytecodeHash;
    uint256 immutable private chainId;

    constructor(address _minter) {
        minter = _minter;
        escrowBytecodeHash = keccak256(type(Escrow721).creationCode);
        chainId = block.chainid;
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

        bytes32 commitHash = Lib.getCommitHash(commit);
        // we expect this step to revert if the NFT is not held in escrow
        new Escrow721{ salt: commitHash }(commit.token, commit.tokenId, claimTo);
    }
}
