module og_nft::staking_rule;

use sui::transfer_policy::{
    Self,
    TransferPolicy,
    TransferPolicyCap,
    TransferRequest
};

// ============== Structs ==============

public struct StakingCap has key, store {
    id: UID,
}

public struct Rule has drop {}

// ============== Public Functions ==============

public fun new_staking_cap(ctx: &mut TxContext): StakingCap {
    StakingCap {
        id: object::new(ctx),
    }
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
