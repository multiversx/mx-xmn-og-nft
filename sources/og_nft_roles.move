module og_nft::og_nft_roles;

use sui::bag::{Self, Bag};
use sui_extensions::two_step_role::{Self, TwoStepRole};

public struct Roles<phantom T> has store {
    data: Bag
}

public struct OwnerRole<phantom T> has drop {}

public struct OwnerKey {} has copy, store, drop;

public(package) fun owner_role_mut<T>(roles: &mut Roles<T>): &mut TwoStepRole<OwnerRole<T>> {
    roles.data.borrow_mut(OwnerKey {})
}

public(package) fun owner_role<T>(roles: &Roles<T>): &TwoStepRole<OwnerRole<T>> {
    roles.data.borrow(OwnerKey {})
}

public fun owner<T>(roles: &Roles<T>): address {
    roles.owner_role().active_address()
}

public fun pending_owner<T>(roles: &Roles<T>): Option<address> {
    roles.owner_role().pending_address()
}

public(package) fun new<T>(
    owner: address,
    ctx: &mut TxContext,
): Roles<T> {
    let mut data = bag::new(ctx);
    data.add(OwnerKey {}, two_step_role::new(OwnerRole<T> {}, owner));

    Roles {
        data
    }
}
