//! CampusCore Badge NFT Contract
//!
//! Issues non-transferable achievement badges to students.
//! Each badge type can only be earned once per student.

#![no_std]
use soroban_sdk::{
    contract, contractimpl, contracttype,
    Address, Env, String, Vec,
};

#[contracttype]
#[derive(Clone, Debug)]
pub struct Badge {
    pub badge_type: String,   // e.g. "top_contributor"
    pub metadata_uri: String, // Storage URL for badge image/metadata
    pub earned_at: u64,
}

#[contract]
pub struct BadgeNFT;

#[contractimpl]
impl BadgeNFT {
    pub fn initialize(env: Env, admin: Address) {
        if env.storage().instance().has(&soroban_sdk::symbol_short!("admin")) {
            panic!("already initialized");
        }
        env.storage().instance().set(&soroban_sdk::symbol_short!("admin"), &admin);
    }

    /// Mint a badge for a student. Each badge type is unique per student.
    pub fn mint(env: Env, student: Address, badge_type: String, metadata_uri: String) {
        let admin: Address = env.storage().instance()
            .get(&soroban_sdk::symbol_short!("admin")).unwrap();
        admin.require_auth();

        // Check student doesn't already have this badge
        let key = (soroban_sdk::symbol_short!("badge"), student.clone(), badge_type.clone());
        if env.storage().persistent().has(&key) {
            panic!("badge already earned");
        }

        let badge = Badge {
            badge_type: badge_type.clone(),
            metadata_uri,
            earned_at: env.ledger().timestamp(),
        };

        // Store individual badge
        env.storage().persistent().set(&key, &badge);

        // Add to student's badge list
        let list_key = (soroban_sdk::symbol_short!("blist"), student.clone());
        let mut badges: Vec<Badge> = env.storage().persistent()
            .get(&list_key)
            .unwrap_or(Vec::new(&env));
        badges.push_back(badge);
        env.storage().persistent().set(&list_key, &badges);
    }

    /// Check if a student has a specific badge.
    pub fn has_badge(env: Env, student: Address, badge_type: String) -> bool {
        let key = (soroban_sdk::symbol_short!("badge"), student, badge_type);
        env.storage().persistent().has(&key)
    }

    /// Get all badges for a student.
    pub fn get_badges(env: Env, student: Address) -> Vec<Badge> {
        let list_key = (soroban_sdk::symbol_short!("blist"), student);
        env.storage().persistent()
            .get(&list_key)
            .unwrap_or(Vec::new(&env))
    }
}
