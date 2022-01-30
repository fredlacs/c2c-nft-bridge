//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IClaimer.sol";
import "./Lib.sol";
import "./Nft.sol";

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

error FailedCall();
error IncorrectCommitInformation();
error NotNftHolder(Nft nft);

contract Minter is Context {
    address immutable public claimer;
    bytes32 immutable public nftBytecodeHash;
    uint256 immutable private chainId;

    // fromChainId => commit.token => commit.tokenId
    mapping(uint256 => mapping(IERC721 => mapping(uint256 => uint256))) public nonce;

    event C2CMint(
        address indexed prevAddr,
        uint256 indexed prevId,
        address minterUser,
        uint256 prevChainId,
        uint256 nonce,
        address to,
        bytes32 indexed commitHash
    );
    
    constructor(address _claimer) {
        claimer = _claimer;
        nftBytecodeHash = keccak256(type(Nft).creationCode);
        chainId = Lib.chainId();
    }
    
    function mint(
        Commit721 calldata commit,
        address mintTo
    ) external {
        /*
         *  During the mint we verify half of the commitment
         *  The other field should be verified offchain whenever you interact with this NFT
         *  They are also lazily verified during a withdrawal
         */
        if(
            commit.minterUser != _msgSender() ||
            commit.toChainId != chainId ||
            commit.nonce < nonce[commit.fromChainId][commit.token][commit.tokenId]
        ) revert IncorrectCommitInformation();
        
        // the commit hash can be stored explicitly or by being used as a create2 salt
        // tradeoff between calldata vs storage here, storage seems like a better call
        // both modes could be supported in parallel, but for simplicity we use storage
        bytes32 commitHash = Lib.getCommitHash(commit);
        
        // TODO: mint in 1155 instead of a new deploy each time
        new Nft{salt: commitHash}(commitHash, address(commit.token), commit.fromChainId, mintTo);

        nonce[commit.fromChainId][commit.token][commit.tokenId] = commit.nonce + 1;
        
        emit C2CMint(
            address(commit.token),
            commit.tokenId,
            commit.minterUser,
            commit.fromChainId,
            commit.nonce,
            mintTo,
            commitHash
        );
    }

    function getNftAddress(
        bytes32 commitHash
    ) public view returns (address) {
        return Create2.computeAddress(commitHash, nftBytecodeHash, address(this));
    }

    function withdraw(
        Commit721 calldata commit,
        address claimTo
    ) external {
        bytes32 commitHash = Lib.getCommitHash(commit);
        Nft nft = Nft(getNftAddress(commitHash));
        
        // TODO: do we need a nonce check here or only on receiver? nonce management can't take minter into account
        if(nft.ownerOf(uint256(commitHash)) != _msgSender()) revert NotNftHolder(nft);
        nft.burn(uint256(commitHash));

        bytes memory dataForCall = abi.encodeWithSelector(
            IClaimer.claimEscrow.selector,
            commit,
            claimTo
        );
        sendCallToClaimer(dataForCall);
    }

    function sendCallToClaimer(bytes memory dataForCall) internal virtual {
        (bool res, ) = claimer.call(dataForCall);
        if(!res) revert FailedCall();
    }
}