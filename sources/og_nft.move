module og_nft::og_nft;

use std::string::String;
use sui::package;
use sui::display;
use sui::event;
use og_nft::og_nft_roles;

const MINT_SUPPLY: u64 = 1000;
const ENotOwner: u64 = 0;

public struct OGNFT has key, store {
    id: UID,
    name: String,
    image_url: String,
}

public struct OG_NFT has drop {}

public struct CollectionCap has key, store {
    id: UID,
    roles: og_nft_roles::Roles<OG_NFT>,
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
    let roles = og_nft_roles::new<OG_NFT>(ctx.sender(), ctx);

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
        roles,
        total_supply: MINT_SUPPLY,        
        minted: 0,
        allowlist_enabled: false
    };

    transfer::public_transfer(publisher, ctx.sender());
    transfer::public_transfer(display_obj, ctx.sender());
    transfer::public_transfer(cap, ctx.sender());
}

public fun mint(
    self: &mut CollectionCap,
    name: String,
    image_url: String,
    receiver: address,
    ctx: &mut TxContext
) {
    assert!(self.roles.owner() == ctx.sender(), ENotOwner);

    assert!(self.minted < self.total_supply, 2);

    let nft = OGNFT {
        id: object::new(ctx),
        name,
        image_url,
    };

    self.minted = self.minted + 1;

    event::emit(OGNFTMinted {
        object_id: object::id(&nft),
        owner: receiver,
    });

    transfer::public_transfer<OGNFT>(nft, receiver);
}

public fun transfer_ownership(self: &mut CollectionCap, new_owner: address, ctx: &TxContext) {
    assert!(self.roles.owner() == ctx.sender(), ENotOwner);

    self.roles.owner_role_mut().begin_role_transfer(new_owner, ctx)
}

public fun accept_ownership(self: &mut CollectionCap, ctx: &TxContext) {
    let pending = self.roles.pending_owner();

    assert!(option::is_some(&pending) && option::borrow(&pending) == ctx.sender(), ENotOwner);

    self.roles.owner_role_mut().accept_role(ctx)
}

#[test_only]
public fun create_for_testing(ctx: &mut TxContext): OGNFT {
    OGNFT {
        id: object::new(ctx),
        name: b"Test NFT".to_string(),
        image_url: b"https://test.com/nft.png".to_string(),
    }
}