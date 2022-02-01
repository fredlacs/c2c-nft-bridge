//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Lib.sol";
import "./Escrow721.sol";
import "./IClaimer.sol";

import "@openzeppelin/contracts/utils/Create2.sol";

error NotMinter();

/// @dev contract intended to be deployed to L1
contract Claimer is IClaimer {
    address immutable public minter;
    bytes32 immutable public escrowBytecodeHash;

    constructor(address _minter) {
        minter = _minter;
        escrowBytecodeHash = keccak256(type(Escrow721).creationCode);
    }

    /// @dev should be overriden to validate L2 to L1 sender is correct
    function calledByMinter() internal virtual view returns (bool) {
        return msg.sender == minter;
    }
    
    function getEscrowAddress(bytes32 commitHash) external view returns (address) {
        return Create2.computeAddress(commitHash, escrowBytecodeHash, address(this));
    }

    /// @dev this is the only codepath that releases NFTs from escrow
    function claimEscrow(
        Commit721 calldata commit,
        address claimTo
    ) external override {
        if(!calledByMinter()) revert NotMinter();

        bytes32 commitHash = Lib.getCommitHash(commit);
        // we expect this step to revert if the NFT is not held in escrow
        new Escrow721{ salt: commitHash }(commit.token, commit.tokenId, claimTo);
    }
}
