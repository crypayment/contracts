// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library Types {
    // keccak256("Claim(uint256 nonce,uint256 deadline,address client,address[] accounts)")
    bytes32 internal constant CLAIM_HASH = 0x35851c1cde7b8f1f91732884cdbdfc42f080e7499ad206a34e4762ac357f24e5;

    struct CloneInfo {
        address instance;
        address creator;
    }

    struct FeeInfo {
        address recipient;
        uint96 percentage;
    }

    struct PaymentInfo {
        address token;
        uint96 amount;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Claim {
        uint256 nonce;
        uint256 deadline;
        address client;
        address[] accounts;
    }

    function hash(Claim calldata claim) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    CLAIM_HASH,
                    claim.nonce,
                    claim.deadline,
                    address(this),
                    keccak256(abi.encodePacked(claim.accounts))
                )
            );
    }
}
