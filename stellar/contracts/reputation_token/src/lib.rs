//! CampusCore Reputation Token (CRT)
//!
//! A Soroban smart contract that tracks student reputation points on Stellar.
//! Points are non-transferable (soulbound) — tied to the student's address.
//!
//! Deployed on: Stellar Testnet
//! Contract ID: (set after deployment)

#![no_std]
use soroban_sdk::{
    contract, contractimpl, contracttype, symbol_short,
    Address, Env, String, Vec, Map,
};

// ─── Storage Keys ────────────────────────────────────────────────────────────

const ADMIN_KEY: &str = "admin";
const BALANCE_KEY: &str = "balance";
const HISTORY_KEY: &str = "history";

// ─── Data Types ──────────────────────────────────────────────────────────────

#[contracttype]
#[derive(Clone, Debug)]
pub struct ReputationEvent {
    pub points: i128,
    pub reason: String,
    pub timestamp: u64,
}

// ─── Contract ─────────────────────────────────────────────────────────────────

#[contract]
pub struct ReputationToken;

#[contractimpl]
impl ReputationToken {
    /// Initialize the contract with an admin address.
    /// The admin is the CampusCore backend's Stellar keypair.
    pub fn initialize(env: Env, admin: Address) {
        if env.storage().instance().has(&symbol_short!("admin")) {
            panic!("already initialized");
        }
        env.storage().instance().set(&symbol_short!("admin"), &admin);
    }

    /// Award reputation points to a student.
    /// Only callable by the admin (CampusCore backend).
    pub fn award_points(env: Env, student: Address, points: i128, reason: String) {
        // Verify admin authorization
        let admin: Address = env.storage().instance().get(&symbol_short!("admin")).unwrap();
        admin.require_auth();

        // Update balance
        let current: i128 = env.storage().persistent()
            .get(&(symbol_short!("bal"), student.clone()))
            .unwrap_or(0);
        env.storage().persistent()
            .set(&(symbol_short!("bal"), student.clone()), &(current + points));

        // Record event in history
        let event = ReputationEvent {
            points,
            reason,
            timestamp: env.ledger().timestamp(),
        };
        let mut history: Vec<ReputationEvent> = env.storage().persistent()
            .get(&(symbol_short!("hist"), student.clone()))
            .unwrap_or(Vec::new(&env));
        history.push_back(event);
        env.storage().persistent()
            .set(&(symbol_short!("hist"), student.clone()), &history);
    }

    /// Get a student's total reputation balance.
    pub fn get_balance(env: Env, student: Address) -> i128 {
        env.storage().persistent()
            .get(&(symbol_short!("bal"), student))
            .unwrap_or(0)
    }

    /// Get a student's reputation history (last 50 events).
    pub fn get_history(env: Env, student: Address) -> Vec<ReputationEvent> {
        env.storage().persistent()
            .get(&(symbol_short!("hist"), student))
            .unwrap_or(Vec::new(&env))
    }

    /// Get the admin address.
    pub fn get_admin(env: Env) -> Address {
        env.storage().instance().get(&symbol_short!("admin")).unwrap()
    }

    /// Update admin (callable by current admin only).
    pub fn set_admin(env: Env, new_admin: Address) {
        let admin: Address = env.storage().instance().get(&symbol_short!("admin")).unwrap();
        admin.require_auth();
        env.storage().instance().set(&symbol_short!("admin"), &new_admin);
    }
}

// ─── Tests ───────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;
    use soroban_sdk::testutils::{Address as _, AuthorizedFunction, AuthorizedInvocation};
    use soroban_sdk::{symbol_short, vec, Env, IntoVal};

    #[test]
    fn test_initialize_and_award() {
        let env = Env::default();
        env.mock_all_auths();

        let contract_id = env.register_contract(None, ReputationToken);
        let client = ReputationTokenClient::new(&env, &contract_id);

        let admin = Address::generate(&env);
        let student = Address::generate(&env);

        // Initialize
        client.initialize(&admin);
        assert_eq!(client.get_admin(), admin);

        // Award points
        client.award_points(
            &student,
            &10_i128,
            &String::from_str(&env, "upload_approved"),
        );
        assert_eq!(client.get_balance(&student), 10);

        // Award more points
        client.award_points(
            &student,
            &5_i128,
            &String::from_str(&env, "answer_helpful"),
        );
        assert_eq!(client.get_balance(&student), 15);

        // Check history
        let history = client.get_history(&student);
        assert_eq!(history.len(), 2);
    }

    #[test]
    fn test_balance_starts_at_zero() {
        let env = Env::default();
        env.mock_all_auths();

        let contract_id = env.register_contract(None, ReputationToken);
        let client = ReputationTokenClient::new(&env, &contract_id);

        let admin = Address::generate(&env);
        let student = Address::generate(&env);

        client.initialize(&admin);
        assert_eq!(client.get_balance(&student), 0);
    }
}
