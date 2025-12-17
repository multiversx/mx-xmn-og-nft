module og_nft::og_nft;

use std::string::String;
use sui::package;
use sui::display;
use sui::event;
use og_nft::og_nft_roles;

// ============== Constants ==============
const MINT_SUPPLY: u64 = 5000;

// ============== Error Codes ==============
const ENotOwner: u64 = 1;
const ESupplyExceeded: u64 = 2;
const EInvalidSupply: u64 = 3;

// ============== Structs ==============
public struct Utility has store, copy, drop {
    staking_apr_boost: String,
    stackable: bool,
    boost_scope: String,
    applies_while_held: bool,
}

public struct Attribute has store, copy, drop {
    trait_type: String,
    value: String,
}

public struct OGNFT has key, store {
    id: UID,
    name: String,
    symbol: String,
    image_url: String,
    description: String,
    attributes: vector<Attribute>,
    utility: Utility,
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
    ];
    let values = vector[
        b"{name}".to_string(),
        b"https://project-url.com".to_string(),
        b"{image_url}".to_string(),
        b"{description}".to_string(),
        b"XMoney Team".to_string(),
    ];

    let mut display_obj = display::new_with_fields<OGNFT>(&publisher, keys, values, ctx);
    display_obj.update_version();

    let cap = CollectionCap {
        id: object::new(ctx),
        roles,
        total_supply: MINT_SUPPLY,        
        minted: 0
    };

    transfer::public_transfer(publisher, ctx.sender());
    transfer::public_transfer(display_obj, ctx.sender());
    transfer::public_transfer(cap, ctx.sender());
}

public fun mint(
    self: &mut CollectionCap,
    receiver: address,
    ctx: &mut TxContext
) {
    assert!(ctx.sender() == self.roles.owner(), ENotOwner);
    assert!(self.minted < self.total_supply, ESupplyExceeded);

    let mut attributes = vector::empty<Attribute>();
    vector::push_back(&mut attributes, Attribute { trait_type: b"APR Boost".to_string(), value: b"+2%".to_string() });
    vector::push_back(&mut attributes, Attribute { trait_type: b"Utility".to_string(), value: b"Staking Boost".to_string() });
    vector::push_back(&mut attributes, Attribute { trait_type: b"Token".to_string(), value: b"XMN".to_string() });
    vector::push_back(&mut attributes, Attribute { trait_type: b"Network".to_string(), value: b"Sui".to_string() });
    vector::push_back(&mut attributes, Attribute { trait_type: b"Boost Type".to_string(), value: b"Permanent While Held".to_string() });
    vector::push_back(&mut attributes, Attribute { trait_type: b"Transferability".to_string(), value: b"Transferable".to_string() });
    vector::push_back(&mut attributes, Attribute { trait_type: b"Version".to_string(), value: b"V1".to_string() });

    let utility_data = Utility {
        staking_apr_boost: b"2%".to_string(),
        stackable: false,
        boost_scope: b"per_wallet".to_string(),
        applies_while_held: false 
    };

    let nft = OGNFT {
        id: object::new(ctx),
        name: b"XMN APR Boost NFT".to_string(),
        symbol: b"XMNBOOST".to_string(),
        description: b"The XMN APR Boost NFT grants its holder a permanent +2% APR increase on XMN staking rewards. Designed for long-term supporters of the XMN ecosystem, this NFT unlocks enhanced staking yields and exclusive benefits across the protocol.".to_string(),
        image_url: b"ipfs://image-cid".to_string(), 
        attributes: attributes,
        utility: utility_data,
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
        attributes: vector::empty<Attribute>(),
        utility: Utility {
            staking_apr_boost: b"0%".to_string(),
            stackable: false,
            boost_scope: b"none".to_string(),
            applies_while_held: false,
        },  
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

public fun get_attributes(nft: &OGNFT): vector<Attribute> {
    nft.attributes
}

public fun get_utility(nft: &OGNFT): Utility {
    nft.utility
}

public fun get_staking_apr_boost(utility: &Utility): String {
    utility.staking_apr_boost
}

public fun is_stackable(utility: &Utility): bool {
    utility.stackable
}

public fun get_boost_scope(utility: &Utility): String {
    utility.boost_scope
}

public fun applies_while_held(utility: &Utility): bool {
    utility.applies_while_held
}
