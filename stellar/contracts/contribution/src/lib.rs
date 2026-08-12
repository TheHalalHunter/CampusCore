//! CampusCore Contribution Proof Contract
//!
//! Records on-chain proof of student resource contributions.
//! Links a student's Stellar address to an approved resource upload.

#![no_std]
use soroban_sdk::{
    contract, contractimpl, contracttype,
    Address, Env, String, Vec,
};

#[contracttype]
#[derive(Clone, Debug)]
pub struct Contribution {
    pub student: Address,
    pub resource_hash: String, // SHA-256 hash of the file
    pub course_id: String,
    pub timestamp: u64,
}

#[contract]
pub struct ContributionProof;

#[contractimpl]
impl ContributionProof {
    pub fn initialize(env: Env, admin: Address) {
        if env.storage().instance().has(&soroban_sdk::symbol_short!("admin")) {
            panic!("already initialized");
        }
        env.storage().instance().set(&soroban_sdk::symbol_short!("admin"), &admin);
    }

    /// Record a resource contribution on-chain.
    /// Called by the backend when a resource is approved.
    pub fn record(
        env: Env,
        student: Address,
        resource_hash: String,
        course_id: String,
    ) {
        let admin: Address = env.storage().instance()
            .get(&soroban_sdk::symbol_short!("admin")).unwrap();
        admin.require_auth();

        let contribution = Contribution {
            student: student.clone(),
            resource_hash: resource_hash.clone(),
            course_id,
            timestamp: env.ledger().timestamp(),
        };

        // Store by resource hash (for verification)
        let hash_key = (soroban_sdk::symbol_short!("hash"), resource_hash);
        env.storage().persistent().set(&hash_key, &contribution);

        // Add to student's contribution list
        let list_key = (soroban_sdk::symbol_short!("clist"), student);
        let mut contributions: Vec<Contribution> = env.storage().persistent()
            .get(&list_key)
            .unwrap_or(Vec::new(&env));
        contributions.push_back(contribution);
        env.storage().persistent().set(&list_key, &contributions);
    }

    /// Verify a contribution by resource hash.
    pub fn verify(env: Env, resource_hash: String) -> Option<Contribution> {
        let hash_key = (soroban_sdk::symbol_short!("hash"), resource_hash);
        env.storage().persistent().get(&hash_key)
    }

    /// Get all contributions by a student.
    pub fn get_contributions(env: Env, student: Address) -> Vec<Contribution> {
        let list_key = (soroban_sdk::symbol_short!("clist"), student);
        env.storage().persistent()
            .get(&list_key)
            .unwrap_or(Vec::new(&env))
    }
}
