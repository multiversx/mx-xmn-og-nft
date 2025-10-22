module bridge_nft::collection;

use std::string;

public struct Collection has key, store {
    id: UID,
    name: string::String,
    description: string::String,
    image_url: string::String,
    creator: address,
    max_supply: u64,
    total_minted: u64,
}

public struct NFT has key, store {
    id: UID,
    name: string::String,
    description: string::String,
    image_url: string::String,
    collection_id: ID,
    serial_number: u64,
}

public fun create_collection(
    name: string::String,
    description: string::String,
    image_url: string::String,
    max_supply: u64,
    ctx: &mut TxContext,
): Collection {
    Collection {
        id: object::new(ctx),
        name,
        description,
        image_url,
        creator: tx_context::sender(ctx),
        max_supply,
        total_minted: 0,
    }
}

public fun mint_nft(
    collection: &mut Collection,
    name: string::String,
    description: string::String,
    image_url: string::String,
    ctx: &mut TxContext,
) {
    assert!(tx_context::sender(ctx) == collection.creator, 0);

    assert!(collection.total_minted < collection.max_supply, 1);

    let serial_number = collection.total_minted + 1;
    collection.total_minted = serial_number;

    let nft = NFT {
        id: object::new(ctx),
        name,
        description,
        image_url,
        collection_id: object::uid_to_inner(&collection.id),
        serial_number,
    };

    transfer::public_transfer(nft, tx_context::sender(ctx));
}
