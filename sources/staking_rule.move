module og_nft::staking_rule;

use sui::transfer_policy::{
    Self,
    TransferPolicy,
    TransferPolicyCap,
    TransferRequest
};

const EUnauthorizedStakingContract: u64 = 1;

public struct StakingConfig has store, drop {
    staking_contract: address,
}

public struct Rule has drop {}

public fun add<T>(
    policy: &mut TransferPolicy<T>,
    cap: &TransferPolicyCap<T>,
    staking_contract: address,
) {
    let config = StakingConfig { staking_contract };
    transfer_policy::add_rule(Rule {}, policy, cap, config);
}

public fun remove<T>(
    policy: &mut TransferPolicy<T>,
    cap: &TransferPolicyCap<T>,
) {
    transfer_policy::remove_rule<T, Rule, StakingConfig>(policy, cap);
}

public fun prove<T>(
    policy: &TransferPolicy<T>,
    request: &mut TransferRequest<T>,
    ctx: &TxContext
) {
    let config: &StakingConfig = transfer_policy::get_rule(Rule {}, policy);

    if (ctx.sender() == config.staking_contract) {
        transfer_policy::add_receipt(Rule {}, request);
        return
    };

}

public fun update_staking_contract<T>(
    policy: &mut TransferPolicy<T>,
    cap: &TransferPolicyCap<T>,
    new_staking_contract: address,
) {
    let config = StakingConfig { staking_contract: new_staking_contract };
    transfer_policy::add_rule(Rule {}, policy, cap, config);
}

public fun get_staking_contract<T>(
    policy: &TransferPolicy<T>,
): address {
    let config: &StakingConfig = transfer_policy::get_rule(Rule {}, policy);
    config.staking_contract
}
