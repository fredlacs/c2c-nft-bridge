//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { IL1 } from "./L1.sol";
import "./Lib.sol";
import "./Nft.sol";

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

contract L2 is Context {
    address immutable public l1Counterpart;
    bytes32 immutable public nftBytecodeHash;
    uint256 immutable private chainId;

    // nonce[commit.fromChainId][commit.token][commit.tokenId]
    mapping(uint256 => mapping(IERC721 => mapping(uint256 => uint256))) public nonce;

    event C2CMint(
        address indexed prevAddr,
        uint256 indexed prevId,
        address minter,
        uint256 prevChainId,
        uint256 nonce,
        address to,
        bytes32 indexed commitHash
    );
    
    constructor(address l1C2C) {
        l1Counterpart = l1C2C;
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
        require(commit.minter == _msgSender(), "NOT_MINTER");
        require(commit.toChainId == chainId, "WRONG_DEST");
        require(commit.nonce > nonce[commit.fromChainId][commit.token][commit.tokenId], "NEED_NEW_NONCE");
        
        // the commit hash can be stored explicitly or by being used as a create2 salt
        // tradeoff between calldata vs storage here, storage seems like a better call
        // both modes could be supported in parallel, but for simplicity we use storage
        bytes32 commitHash = Lib.getCommitHash(commit);
        
        // TODO: mint in 1155 instead of a new deploy each time
        new Nft{salt: commitHash}(commitHash, address(commit.token), commit.fromChainId, mintTo);

        nonce[commit.fromChainId][commit.token][commit.tokenId] = commit.nonce;
        
        emit C2CMint(
            address(commit.token),
            commit.tokenId,
            commit.minter,
            commit.fromChainId,
            commit.nonce,
            mintTo,
            commitHash
        );
    }

    function getL2Addr(
        bytes32 commitHash
    ) public view returns (address) {
        return Create2.computeAddress(commitHash, nftBytecodeHash, address(this));
    }

    function withdraw(
        Commit721 calldata commit,
        address claimTo
    ) external {
        bytes32 commitHash = Lib.getCommitHash(commit);
        // TODO: can we optimise this validation to reduce calldata?
        Nft nft = Nft(getL2Addr(commitHash));
        require(nft.ownerOf(uint256(commitHash)) == _msgSender(), "NOT_NFT_HOLDER");
        
        // TODO: instead of burn, check if escrowed? this makes it possible to do O(1) settlement
        // TODO: do we need a nonce check here or only on receiver?
        nft.burn(uint256(commitHash));

        bytes memory dataForCall = abi.encodeWithSelector(
            IL1.claimEscrow.selector,
            commit,
            claimTo
        );
        sendToL1Counterpart(dataForCall);
    }

    function sendToL1Counterpart(bytes memory dataForCall) internal virtual {
        (bool res, ) = l1Counterpart.call(dataForCall);
        require(res, "FAIL_SEND_TO_L1");
    }
}
