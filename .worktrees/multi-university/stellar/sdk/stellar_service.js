/**
 * CampusCore — Stellar SDK Service
 *
 * Handles interaction with Stellar network and Soroban contracts
 * from the JavaScript layer (used by Flutter Web via JS interop
 * and by the NestJS backend).
 *
 * Stellar SDK docs: https://stellar.github.io/js-stellar-sdk
 */

import * as StellarSdk from '@stellar/stellar-sdk';

const NETWORK_PASSPHRASE = StellarSdk.Networks.TESTNET;
const HORIZON_URL = 'https://horizon-testnet.stellar.org';
const SOROBAN_RPC_URL = 'https://soroban-testnet.stellar.org';

// Contract IDs (set after deployment to testnet)
const CONTRACT_IDS = {
  reputationToken: process.env.REPUTATION_TOKEN_CONTRACT_ID || '',
  badgeNFT: process.env.BADGE_NFT_CONTRACT_ID || '',
  contributionProof: process.env.CONTRIBUTION_CONTRACT_ID || '',
};

const server = new StellarSdk.Horizon.Server(HORIZON_URL);
const sorobanServer = new StellarSdk.SorobanRpc.Server(SOROBAN_RPC_URL);

/**
 * Get a student's on-chain reputation balance.
 * @param {string} studentAddress - Stellar public key
 * @returns {Promise<bigint>}
 */
async function getReputationBalance(studentAddress) {
  const contract = new StellarSdk.Contract(CONTRACT_IDS.reputationToken);
  const result = await sorobanServer.simulateTransaction(
    buildTransaction(
      contract.call('get_balance', StellarSdk.Address.fromString(studentAddress).toScVal())
    )
  );
  return StellarSdk.scValToNative(result.result.retval);
}

/**
 * Get a student's on-chain badges.
 * @param {string} studentAddress
 * @returns {Promise<Array>}
 */
async function getStudentBadges(studentAddress) {
  const contract = new StellarSdk.Contract(CONTRACT_IDS.badgeNFT);
  const result = await sorobanServer.simulateTransaction(
    buildTransaction(
      contract.call('get_badges', StellarSdk.Address.fromString(studentAddress).toScVal())
    )
  );
  return StellarSdk.scValToNative(result.result.retval);
}

/**
 * Verify a resource contribution on-chain.
 * @param {string} resourceHash - SHA-256 hash of the file
 * @returns {Promise<Object|null>}
 */
async function verifyContribution(resourceHash) {
  const contract = new StellarSdk.Contract(CONTRACT_IDS.contributionProof);
  const result = await sorobanServer.simulateTransaction(
    buildTransaction(
      contract.call(
        'verify',
        StellarSdk.nativeToScVal(resourceHash, { type: 'string' })
      )
    )
  );
  return StellarSdk.scValToNative(result.result.retval);
}

/**
 * Build a basic Soroban transaction for simulation.
 * @param {StellarSdk.xdr.Operation} operation
 * @returns {StellarSdk.Transaction}
 */
function buildTransaction(operation) {
  return new StellarSdk.TransactionBuilder(
    new StellarSdk.Account('GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN', '0'),
    { fee: '100', networkPassphrase: NETWORK_PASSPHRASE }
  )
    .addOperation(operation)
    .setTimeout(30)
    .build();
}

export {
  getReputationBalance,
  getStudentBadges,
  verifyContribution,
  CONTRACT_IDS,
  NETWORK_PASSPHRASE,
  HORIZON_URL,
  SOROBAN_RPC_URL,
};
