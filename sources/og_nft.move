module og_nft::og_nft;

use std::string::String;
use sui::package;
use sui::display;
use sui::event;

const MINT_SUPPLY: u64 = 1000;

public struct OGNFT has key, store {
    id: UID,
    name: String,
    image_url: String,
}

public struct OG_NFT has drop {}

public struct CollectionCap has key, store {
    id: UID,
    owner: address,
    total_supply: u64,
    minted: u64,
    allowlist_enabled: bool,
}

public struct OGNFTMinted has copy, drop {
    object_id: ID,
    owner: address,
}

fun init(otw: OG_NFT, ctx: &mut TxContext) {
    let publisher = package::claim(otw, ctx);

    let keys = vector[
        b"name".to_string(),
        b"image_url".to_string(),
        b"description".to_string()
    ];
    let values = vector[
        b"{name}".to_string(),
        b"{image_url}".to_string(),
        b"OG NFT from official collection".to_string()
    ];
    let mut display_obj = display::new_with_fields<OGNFT>(&publisher, keys, values, ctx);
    display_obj.update_version();

    let cap = CollectionCap {
        id: object::new(ctx),
        owner: ctx.sender(),
        total_supply: MINT_SUPPLY,        
        minted: 0,
        allowlist_enabled: false
    };

    transfer::public_transfer(publisher, ctx.sender());
    transfer::public_transfer(display_obj, ctx.sender());
    transfer::public_transfer(cap, ctx.sender());
}

public fun mint(
    cap_obj: &mut CollectionCap,
    name: String,
    image_url: String,
    receiver: address,
    ctx: &mut TxContext
) {
    assert!(ctx.sender() == cap_obj.owner, 1);

    assert!(cap_obj.minted < cap_obj.total_supply, 2);

    let nft = OGNFT {
        id: object::new(ctx),
        name,
        image_url,
    };

    cap_obj.minted = cap_obj.minted + 1;

    event::emit(OGNFTMinted {
        object_id: object::id(&nft),
        owner: receiver,
    });

    transfer::public_transfer<OGNFT>(nft, receiver);
}


#[test_only]
public fun create_for_testing(ctx: &mut TxContext): OGNFT {
    OGNFT {
        id: object::new(ctx),
        name: b"Test NFT".to_string(),
        image_url: b"https://test.com/nft.png".to_string(),
    }
}