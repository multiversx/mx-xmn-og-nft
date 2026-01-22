module og_nft::og_nft;

use std::string::String;
use sui::package;
use sui::display;
use sui::event;
use og_nft::og_nft_roles;
use sui::vec_map::{Self, VecMap};
use sui::transfer_policy;

// ============== Constants ==============
const MINT_SUPPLY: u64 = 1000;

// ============== Error Codes ==============
const ENotOwner: u64 = 1;
const ESupplyExceeded: u64 = 2;
const EInvalidSupply: u64 = 3;

// ============== Structs ==============
public struct OGNFT has key, store {
    id: UID,
    name: String,
    symbol: String,
    image_url: String,
    description: String,
    attributes: VecMap<String, String>,
}

public struct OG_NFT has drop {}

public struct CollectionCap has key, store {
    id: UID,
    roles: og_nft_roles::Roles<OG_NFT>,
    total_supply: u64,
    minted: u64,
}

// =============== Events ==============
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
        b"project_url".to_string(),
        b"description".to_string(),
        b"creator".to_string(),
        b"collection_name".to_string(),
        b"collection_description".to_string(),
        b"collection_media_url".to_string(),
    ];
    let values = vector[
        b"{name}".to_string(),
        b"{image_url}".to_string(),
        b"https://stake.xmoney.com".to_string(),
        b"{description}".to_string(),
        b"XMoney Team".to_string(),
        b"XMN APR Boost Collection".to_string(),
        b"Official XMoney NFT collection providing permanent staking APR boosts for XMN token holders. Each NFT grants +2% APR when staked in the XMoney protocol.".to_string(),
        b"https://ipfs.io/ipfs/bafybeifhunxvdl2lylrly2kjpqwchjtyqyyakpstkgsqi7cr6a367jbkfe".to_string(),
    ];

    let mut display_obj = display::new_with_fields<OGNFT>(&publisher, keys, values, ctx);
    display_obj.update_version();

    // Create TransferPolicy for royalty enforcement
    let (transfer_policy, policy_cap) = transfer_policy::new<OGNFT>(&publisher, ctx);

    let cap = CollectionCap {
        id: object::new(ctx),
        roles,
        total_supply: MINT_SUPPLY,
        minted: 0
    };

    transfer::public_transfer(publisher, ctx.sender());
    transfer::public_transfer(display_obj, ctx.sender());
    transfer::public_share_object(transfer_policy);
    transfer::public_transfer(policy_cap, ctx.sender());
    transfer::public_transfer(cap, ctx.sender());
}

public fun mint(
    self: &mut CollectionCap,
    receiver: address,
    ctx: &mut TxContext
) {
    assert!(ctx.sender() == self.roles.owner(), ENotOwner);
    assert!(self.minted < self.total_supply, ESupplyExceeded);

    let mut attributes = vec_map::empty<String, String>();

    vec_map::insert(&mut attributes, b"APR Boost".to_string(), b"+2%".to_string());
    vec_map::insert(&mut attributes, b"Utility".to_string(), b"Staking Boost".to_string());
    vec_map::insert(&mut attributes, b"Token".to_string(), b"XMN".to_string());
    vec_map::insert(&mut attributes, b"Network".to_string(), b"Sui".to_string());
    vec_map::insert(&mut attributes, b"Boost Type".to_string(), b"Permanent While Staked".to_string());
    vec_map::insert(&mut attributes, b"Transferability".to_string(), b"Transferable".to_string());
    vec_map::insert(&mut attributes, b"Version".to_string(), b"V1".to_string());

    // Merged utility data (4 entries)
    vec_map::insert(&mut attributes, b"staking_apr_boost".to_string(), b"2%".to_string());
    vec_map::insert(&mut attributes, b"stackable".to_string(), b"false".to_string());
    vec_map::insert(&mut attributes, b"boost_scope".to_string(), b"per_wallet".to_string());
    vec_map::insert(&mut attributes, b"applies_while_held".to_string(), b"false".to_string());

    let nft = OGNFT {
        id: object::new(ctx),
        name: b"XMN APR Boost NFT".to_string(),
        symbol: b"XMNBOOST".to_string(),
        description: b"The XMN APR Boost NFT grants its holder a permanent +2% APR increase on XMN staking rewards. Designed for long-term supporters of the XMN ecosystem, this NFT unlocks enhanced staking yields and exclusive benefits across the protocol.".to_string(),
        image_url: b"https://ipfs.io/ipfs/bafybeifhunxvdl2lylrly2kjpqwchjtyqyyakpstkgsqi7cr6a367jbkfe".to_string(),
        attributes: attributes,
    };

    self.minted = self.minted + 1;

    event::emit(OGNFTMinted {
        object_id: object::id(&nft),
        owner: receiver,
    });

    transfer::public_transfer<OGNFT>(nft, receiver);
}

public fun set_total_supply(
    collection: &mut CollectionCap,
    new_supply: u64,
    ctx: &mut TxContext
) {
    assert!(ctx.sender() == collection.roles.owner(), ENotOwner);
    assert!(new_supply >= collection.minted, EInvalidSupply);
    collection.total_supply = new_supply;
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
        description: b"Test NFT for unit testing".to_string(),
        symbol: b"TEST".to_string(),
        attributes: vec_map::empty<String, String>(),
    }
}

// ============== Test Helper Functions ==============

#[test_only]
public fun create_collection_cap_for_testing(ctx: &mut TxContext): CollectionCap {
    CollectionCap {
        id: object::new(ctx),
        roles: og_nft_roles::new<OG_NFT>(ctx.sender(), ctx),
        total_supply: MINT_SUPPLY,
        minted: 0,
    }
}

#[test_only]
public fun create_collection_cap_with_supply_for_testing(supply: u64, ctx: &mut TxContext): CollectionCap {
    CollectionCap {
        id: object::new(ctx),
        roles: og_nft_roles::new<OG_NFT>(ctx.sender(), ctx),
        total_supply: supply,
        minted: 0,
    }
}

// ============== Getter Functions ==============
public fun get_owner(cap: &CollectionCap): address {
    cap.roles.owner()
}

public fun get_total_supply(cap: &CollectionCap): u64 {
    cap.total_supply
}

public fun get_minted(cap: &CollectionCap): u64 {
    cap.minted
}

public fun get_name(nft: &OGNFT): String {
    nft.name
}

public fun get_symbol(nft: &OGNFT): String {
    nft.symbol
}

public fun get_description(nft: &OGNFT): String {
    nft.description
}

public fun get_image_url(nft: &OGNFT): String {
    nft.image_url
}

public fun get_attributes(nft: &OGNFT): &VecMap<String, String> {
    &nft.attributes
}

