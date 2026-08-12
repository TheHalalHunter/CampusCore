# CampusCore Stellar Integration

This directory contains the Soroban smart contracts and JavaScript SDK helpers for the CampusCore blockchain layer.

## Structure

```
stellar/
├── contracts/
│   ├── reputation_token/   # CRT reputation token (Rust/Soroban)
│   ├── badge_nft/          # Achievement badge NFTs (Rust/Soroban)
│   └── contribution/       # Resource contribution proof (Rust/Soroban)
└── sdk/
    ├── freighter.js        # Freighter wallet integration
    └── stellar_service.js  # Stellar SDK helpers
```

## Setup

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Add WASM target
rustup target add wasm32-unknown-unknown

# Install Soroban CLI
cargo install --locked soroban-cli

# Build a contract
cd contracts/reputation_token
cargo build --target wasm32-unknown-unknown --release

# Run tests
cargo test
```

## Deploy to Testnet

```bash
# Get testnet XLM
curl https://friendbot.stellar.org/?addr=YOUR_ADDRESS

# Deploy reputation token
soroban contract deploy \
  --wasm target/wasm32-unknown-unknown/release/reputation_token.wasm \
  --source YOUR_SECRET_KEY \
  --network testnet

# Initialize contract
soroban contract invoke \
  --id CONTRACT_ID \
  --source YOUR_SECRET_KEY \
  --network testnet \
  -- initialize \
  --admin YOUR_ADDRESS
```

## See Also

- [STELLAR.md](../STELLAR.md) — full integration spec
- [CONTRIBUTING.md](../CONTRIBUTING.md) — how to contribute
