//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./Lib.sol";

error NoTokenUriAvailable();
error NotFactory();

contract Nft is ERC721 {
    bytes32 immutable public commitHash;
    address immutable public prevAddr;
    uint256 immutable public prevChainId;
    address immutable public factory;

    constructor(
        bytes32 _commitHash,
        address _prevAddr,
        uint256 _prevChainId,
        address mintTo
    ) ERC721("C2C_Bridged_Nft", "C2CNFT") {
        commitHash = _commitHash;
        prevAddr = _prevAddr;
        prevChainId = _prevChainId;
        factory = msg.sender;

        // TODO: is there a better scheme for remapping tokenIds?
        // we remap tokenId so we don't clash namespaces if doing everything in
        // the same 1155 token contract
        _mint(mintTo, uint256(_commitHash));
    }

    function tokenURI(uint256 /* tokenId */) public view virtual override returns (string memory) {
        // TODO: implement EIP-3668 CCIP Read Secure offchain data retrieval
        revert NoTokenUriAvailable();
    }

    function burn(uint256 tokenId) external {
        if(msg.sender != factory) revert NotFactory();
        _burn(tokenId);
    }
}
