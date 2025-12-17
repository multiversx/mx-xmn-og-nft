#[test_only]
module og_nft::og_nft_tests;

use sui::test_scenario::{Self as ts, Scenario};
use og_nft::og_nft::{Self, CollectionCap, OGNFT};

const ADMIN: address = @0xAD;
const USER1: address = @0xB1;
const USER2: address = @0xB2;

// ============== Helper Functions ==============

fun create_collection_cap_for_testing(scenario: &mut Scenario) {
    ts::next_tx(scenario, ADMIN);
    {
        let ctx = ts::ctx(scenario);
        let cap = og_nft::create_collection_cap_for_testing(ctx);
        transfer::public_transfer(cap, ADMIN);
    };
}

// ============== Mint Tests ==============

#[test]
fun test_mint_success() {
    let mut scenario = ts::begin(ADMIN);
    
    create_collection_cap_for_testing(&mut scenario);
    
    ts::next_tx(&mut scenario, ADMIN);
    {
        let mut cap = ts::take_from_sender<CollectionCap>(&scenario);
        og_nft::mint(&mut cap, USER1, ts::ctx(&mut scenario));
        
        assert!(og_nft::get_minted(&cap) == 1, 0);
        
        ts::return_to_sender(&scenario, cap);
    };
    
    ts::next_tx(&mut scenario, USER1);
    {
        let nft = ts::take_from_sender<OGNFT>(&scenario);
        
        assert!(og_nft::get_name(&nft) == b"XMN APR Boost NFT".to_string(), 1);
        assert!(og_nft::get_symbol(&nft) == b"XMNBOOST".to_string(), 2);
        
        ts::return_to_sender(&scenario, nft);
    };
    
    ts::end(scenario);
}

#[test]
fun test_mint_multiple() {
    let mut scenario = ts::begin(ADMIN);
    
    create_collection_cap_for_testing(&mut scenario);
    
    ts::next_tx(&mut scenario, ADMIN);
    {
        let mut cap = ts::take_from_sender<CollectionCap>(&scenario);
        og_nft::mint(&mut cap, USER1, ts::ctx(&mut scenario));
        assert!(og_nft::get_minted(&cap) == 1, 0);
        ts::return_to_sender(&scenario, cap);
    };
    
    ts::next_tx(&mut scenario, ADMIN);
    {
        let mut cap = ts::take_from_sender<CollectionCap>(&scenario);
        og_nft::mint(&mut cap, USER2, ts::ctx(&mut scenario));
        assert!(og_nft::get_minted(&cap) == 2, 1);
        ts::return_to_sender(&scenario, cap);
    };
    
    ts::next_tx(&mut scenario, USER1);
    {
        assert!(ts::has_most_recent_for_sender<OGNFT>(&scenario), 2);
    };
    
    ts::next_tx(&mut scenario, USER2);
    {
        assert!(ts::has_most_recent_for_sender<OGNFT>(&scenario), 3);
    };
    
    ts::end(scenario);
}

#[test]
#[expected_failure]
fun test_mint_not_owner_fails() {
    let mut scenario = ts::begin(ADMIN);
    
    create_collection_cap_for_testing(&mut scenario);
    
    ts::next_tx(&mut scenario, ADMIN);
    {
        let cap = ts::take_from_sender<CollectionCap>(&scenario);
        transfer::public_transfer(cap, USER1);
    };
    
    ts::next_tx(&mut scenario, USER1);
    {
        let mut cap = ts::take_from_sender<CollectionCap>(&scenario);
        og_nft::mint(&mut cap, USER2, ts::ctx(&mut scenario));
        ts::return_to_sender(&scenario, cap);
    };
    
    ts::end(scenario);
}

#[test]
#[expected_failure]
fun test_mint_supply_exceeded_fails() {
    let mut scenario = ts::begin(ADMIN);
    
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        let cap = og_nft::create_collection_cap_with_supply_for_testing(1, ctx);
        transfer::public_transfer(cap, ADMIN);
    };
    
    ts::next_tx(&mut scenario, ADMIN);
    {
        let mut cap = ts::take_from_sender<CollectionCap>(&scenario);
        og_nft::mint(&mut cap, USER1, ts::ctx(&mut scenario));
        ts::return_to_sender(&scenario, cap);
    };
    
    ts::next_tx(&mut scenario, ADMIN);
    {
        let mut cap = ts::take_from_sender<CollectionCap>(&scenario);
        og_nft::mint(&mut cap, USER2, ts::ctx(&mut scenario));
        ts::return_to_sender(&scenario, cap);
    };
    
    ts::end(scenario);
}

#[test]
fun test_nft_attributes() {
    let mut scenario = ts::begin(ADMIN);
    
    create_collection_cap_for_testing(&mut scenario);
    
    ts::next_tx(&mut scenario, ADMIN);
    {
        let mut cap = ts::take_from_sender<CollectionCap>(&scenario);
        og_nft::mint(&mut cap, USER1, ts::ctx(&mut scenario));
        ts::return_to_sender(&scenario, cap);
    };
    
    ts::next_tx(&mut scenario, USER1);
    {
        let nft = ts::take_from_sender<OGNFT>(&scenario);
        
        let attrs = og_nft::get_attributes(&nft);
        assert!(vector::length(&attrs) == 7, 0);
        
        ts::return_to_sender(&scenario, nft);
    };
    
    ts::end(scenario);
}

#[test]
fun test_nft_utility() {
    let mut scenario = ts::begin(ADMIN);
    
    create_collection_cap_for_testing(&mut scenario);
    
    ts::next_tx(&mut scenario, ADMIN);
    {
        let mut cap = ts::take_from_sender<CollectionCap>(&scenario);
        og_nft::mint(&mut cap, USER1, ts::ctx(&mut scenario));
        ts::return_to_sender(&scenario, cap);
    };
    
    ts::next_tx(&mut scenario, USER1);
    {
        let nft = ts::take_from_sender<OGNFT>(&scenario);
        
        let utility = og_nft::get_utility(&nft);
        assert!(og_nft::get_staking_apr_boost(&utility) == b"2%".to_string(), 0);
        assert!(og_nft::is_stackable(&utility) == false, 1);
        assert!(og_nft::get_boost_scope(&utility) == b"per_wallet".to_string(), 2);
        
        ts::return_to_sender(&scenario, nft);
    };
    
    ts::end(scenario);
}

#[test]
fun test_collection_cap_initial_state() {
    let mut scenario = ts::begin(ADMIN);
    
    create_collection_cap_for_testing(&mut scenario);
    
    ts::next_tx(&mut scenario, ADMIN);
    {
        let cap = ts::take_from_sender<CollectionCap>(&scenario);
        
        assert!(og_nft::get_owner(&cap) == ADMIN, 0);
        assert!(og_nft::get_total_supply(&cap) == 10000, 1);
        assert!(og_nft::get_minted(&cap) == 0, 2);
        
        ts::return_to_sender(&scenario, cap);
    };
    
    ts::end(scenario);
}
