# CampusCore × Stellar Integration

> **Status:** Open for Contributors — Next Wave  
> **Network:** Stellar Testnet (then Mainnet)  
> **Smart Contracts:** Soroban (Rust)  
> **Wallet:** Freighter  
> **SDK:** @stellar/stellar-sdk

---

## Vision

CampusCore is integrating Stellar blockchain to give students **true ownership** of their academic achievements. Reputation points, badges, and resource contributions will be recorded on-chain — verifiable by anyone, portable across platforms, and immune to manipulation.

Think of it as a **decentralized academic credential layer** built on top of CampusCore.

---

## What We Are Building

### 1. CampusCore Reputation Token (CRT)
A Soroban-based token that represents a student's reputation on the platform.

- Earned by uploading approved resources, answering questions, helping peers
- Non-transferable (soulbound) — tied to the student's Stellar address
- Displayed on profile alongside the off-chain reputation score
- Future: can be used to unlock premium features or vote on platform decisions

### 2. On-Chain Badges (Achievement NFTs)
Each badge (Fresh Scholar, Bookworm, Top Contributor, etc.) will be issued as a Stellar asset.

- Minted when a student earns a badge
- Stored in the student's Freighter wallet
- Verifiable by employers, institutions, or other platforms
- Badge metadata (name, description, date earned) stored off-chain with on-chain proof

### 3. Resource Contribution Proof
When a student uploads a resource that gets approved, a transaction is recorded on Stellar.

- Links the student's Stellar address to the resource hash
- Proves authorship and contribution date
- Cannot be altered or deleted

### 4. Academic Certificates (Future — Mainnet)
Final year students can receive a Stellar-based certificate of course completion.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Flutter App                        │
│                                                      │
│   Freighter Wallet ──► Stellar SDK (JS via WebView) │
│           │                                          │
│           ▼                                          │
│   Sign transactions with student's keypair          │
└──────────────┬──────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────┐
│                  NestJS Backend                      │
│                                                      │
│   StellarModule ──► Stellar SDK (Node.js)           │
│         │                                            │
│         ├── Submit transactions to Soroban          │
│         ├── Read contract state                     │
│         └── Listen for contract events             │
└──────────────┬──────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────┐
│              Stellar Network (Testnet)               │
│                                                      │
│   Soroban Contracts:                                │
│   ├── reputation_token.rs   (CRT token)             │
│   ├── badge_nft.rs          (Achievement badges)    │
│   └── contribution.rs       (Resource proof)        │
└─────────────────────────────────────────────────────┘
```

---

## Smart Contract Interfaces

### 1. Reputation Token Contract (`reputation_token.rs`)

```rust
pub trait ReputationToken {
    // Award points to a student (called by backend after verified action)
    fn award_points(env: Env, student: Address, points: i128, reason: String);

    // Get a student's total reputation points
    fn get_balance(env: Env, student: Address) -> i128;

    // Get reputation history for a student
    fn get_history(env: Env, student: Address) -> Vec<ReputationEvent>;

    // Admin: set authorized caller (backend address)
    fn set_admin(env: Env, admin: Address);
}

pub struct ReputationEvent {
    pub points: i128,
    pub reason: String,
    pub timestamp: u64,
}
```

### 2. Badge NFT Contract (`badge_nft.rs`)

```rust
pub trait BadgeNFT {
    // Mint a badge for a student (called by backend)
    fn mint(env: Env, student: Address, badge_type: String, metadata_uri: String);

    // Check if a student holds a specific badge
    fn has_badge(env: Env, student: Address, badge_type: String) -> bool;

    // Get all badges for a student
    fn get_badges(env: Env, student: Address) -> Vec<Badge>;
}

pub struct Badge {
    pub badge_type: String,    // e.g. "top_contributor"
    pub metadata_uri: String,  // IPFS or Supabase storage URL
    pub earned_at: u64,
}
```

### 3. Contribution Proof Contract (`contribution.rs`)

```rust
pub trait ContributionProof {
    // Record a resource contribution
    fn record(env: Env, student: Address, resource_hash: String, course_id: String);

    // Verify a contribution exists
    fn verify(env: Env, resource_hash: String) -> Option<Contribution>;

    // Get all contributions by a student
    fn get_contributions(env: Env, student: Address) -> Vec<Contribution>;
}

pub struct Contribution {
    pub student: Address,
    pub resource_hash: String,
    pub course_id: String,
    pub timestamp: u64,
}
```

---

## Backend Integration (NestJS)

A new `StellarModule` will be added to the backend:

```
backend/src/modules/stellar/
├── stellar.module.ts
├── stellar.service.ts          # Stellar SDK interactions
├── stellar.controller.ts       # API endpoints for wallet connection
└── contracts/
    ├── reputation.contract.ts  # Contract call wrappers
    ├── badge.contract.ts
    └── contribution.contract.ts
```

### New API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/stellar/wallet/connect` | Connect Freighter wallet to account |
| GET | `/stellar/reputation/:address` | Get on-chain reputation balance |
| GET | `/stellar/badges/:address` | Get on-chain badges |
| POST | `/stellar/award-points` | Award reputation points (internal) |
| POST | `/stellar/mint-badge` | Mint a badge NFT (internal) |
| POST | `/stellar/record-contribution` | Record resource contribution proof |

---

## Frontend Integration (Flutter)

### Freighter Wallet on Web

Since Freighter is a browser extension, Flutter Web uses JavaScript interop:

```dart
// lib/core/stellar/freighter_service.dart
class FreighterService {
  // Check if Freighter is installed
  Future<bool> isInstalled();

  // Request wallet connection
  Future<String> connect(); // returns stellar address

  // Sign a transaction
  Future<String> signTransaction(String xdr);

  // Get public key
  Future<String> getPublicKey();
}
```

### Stellar Profile Widget

The student profile will show:
- Stellar wallet address (truncated)
- On-chain CRT balance
- On-chain badges with verification link

---

## Development Setup for Stellar Contributors

### Prerequisites
```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Add WASM target
rustup target add wasm32-unknown-unknown

# Install Soroban CLI
cargo install --locked soroban-cli

# Install Stellar SDK (for backend)
cd backend && npm install @stellar/stellar-sdk
```

### Deploy to Testnet
```bash
cd stellar/contracts/reputation_token

# Build
cargo build --target wasm32-unknown-unknown --release

# Deploy to testnet
soroban contract deploy \
  --wasm target/wasm32-unknown-unknown/release/reputation_token.wasm \
  --source YOUR_SECRET_KEY \
  --network testnet

# Invoke a function
soroban contract invoke \
  --id CONTRACT_ID \
  --source YOUR_SECRET_KEY \
  --network testnet \
  -- get_balance \
  --student STUDENT_ADDRESS
```

### Get Testnet XLM (Friendbot)
```
https://friendbot.stellar.org/?addr=YOUR_STELLAR_ADDRESS
```

---

## Contribution Opportunities

These are open issues for Stellar contributors:

| # | Task | Difficulty | Label |
|---|------|------------|-------|
| 1 | Implement `reputation_token.rs` Soroban contract | Medium | `stellar` `smart-contract` |
| 2 | Implement `badge_nft.rs` Soroban contract | Medium | `stellar` `smart-contract` |
| 3 | Implement `contribution.rs` Soroban contract | Easy | `stellar` `smart-contract` |
| 4 | Write Soroban contract tests | Easy | `stellar` `testing` |
| 5 | Build `StellarModule` in NestJS backend | Medium | `stellar` `backend` |
| 6 | Build `FreighterService` in Flutter Web | Hard | `stellar` `frontend` |
| 7 | Add Stellar wallet section to Profile screen | Medium | `stellar` `frontend` |
| 8 | Deploy contracts to Stellar Testnet | Easy | `stellar` `devops` |
| 9 | Write Stellar integration tests | Medium | `stellar` `testing` |
| 10 | Document contract ABI and deployment guide | Easy | `stellar` `docs` |

---

## Resources

- [Stellar Developers Docs](https://developers.stellar.org)
- [Soroban Smart Contracts](https://soroban.stellar.org)
- [Freighter Wallet API](https://docs.freighter.app)
- [Stellar SDK (JavaScript)](https://stellar.github.io/js-stellar-sdk)
- [Stellar Testnet Explorer](https://stellar.expert/explorer/testnet)
- [Soroban by Example](https://soroban.stellar.org/docs/learn/getting-started)

---

## Contact

If you want to work on the Stellar integration, open a GitHub issue with the `stellar` label or start a discussion. Tag `@TheHalalHunter` to get assigned.

---

*This is CampusCore's next wave. Be part of it.*
