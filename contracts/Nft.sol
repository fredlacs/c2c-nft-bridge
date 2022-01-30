//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./Lib.sol";

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

    function burn(uint256 tokenId) external {
        require(msg.sender == factory, "NOT_FACTORY");
        _burn(tokenId);
    }
}
