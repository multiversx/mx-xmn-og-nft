module og_nft::staking_rule;

use sui::transfer_policy::{
    Self,
    TransferPolicy,
    TransferPolicyCap,
    TransferRequest
};

// ============== Structs ==============

public struct AdminCap has key, store {
    id: UID,
}

public struct StakingCap has key, store {
    id: UID,
}

public struct Rule has drop {}

fun init(ctx: &mut TxContext) {
    transfer::transfer(
        AdminCap { id: object::new(ctx) },
        ctx.sender()
    );
}

// ============== Public Functions ==============

#[allow(lint(self_transfer))]
public fun new_staking_cap(
    _admin: &AdminCap,  
    ctx: &mut TxContext
) {
    transfer::transfer(
        StakingCap { id: object::new(ctx) },
        ctx.sender()
    );
}

public fun add<T>(
    policy: &mut TransferPolicy<T>,
    cap: &TransferPolicyCap<T>,
) {
    transfer_policy::add_rule(Rule {}, policy, cap, true);
}

public fun remove<T>(
    policy: &mut TransferPolicy<T>,
    cap: &TransferPolicyCap<T>,
) {
    transfer_policy::remove_rule<T, Rule, bool>(policy, cap);
}

public fun prove<T>(
    _cap: &StakingCap,  // Proof of authorization
    request: &mut TransferRequest<T>,
) {
    transfer_policy::add_receipt(Rule {}, request);
}
