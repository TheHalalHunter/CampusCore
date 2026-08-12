/**
 * CampusCore — Freighter Wallet Integration
 *
 * This module wraps the Freighter browser extension API
 * for use in the CampusCore Flutter Web app via JS interop.
 *
 * Freighter docs: https://docs.freighter.app
 */

/**
 * Check if Freighter is installed in the browser.
 * @returns {boolean}
 */
async function isFreighterInstalled() {
  return typeof window.freighter !== 'undefined';
}

/**
 * Request connection to the user's Freighter wallet.
 * @returns {Promise<string>} The user's Stellar public key
 */
async function connectFreighter() {
  if (!(await isFreighterInstalled())) {
    throw new Error(
      'Freighter wallet is not installed. ' +
      'Please install it from https://freighter.app'
    );
  }
  const { publicKey } = await window.freighter.requestAccess();
  return publicKey;
}

/**
 * Get the connected wallet's public key.
 * @returns {Promise<string>}
 */
async function getPublicKey() {
  if (!(await isFreighterInstalled())) {
    throw new Error('Freighter is not installed.');
  }
  const { publicKey } = await window.freighter.getPublicKey();
  return publicKey;
}

/**
 * Sign a Stellar XDR transaction with Freighter.
 * @param {string} xdr - The transaction XDR string
 * @param {string} network - 'TESTNET' or 'PUBLIC'
 * @returns {Promise<string>} Signed XDR
 */
async function signTransaction(xdr, network = 'TESTNET') {
  if (!(await isFreighterInstalled())) {
    throw new Error('Freighter is not installed.');
  }
  const { signedXDR } = await window.freighter.signTransaction(xdr, {
    network,
  });
  return signedXDR;
}

/**
 * Check which network Freighter is connected to.
 * @returns {Promise<string>} 'TESTNET' or 'PUBLIC'
 */
async function getNetwork() {
  if (!(await isFreighterInstalled())) {
    throw new Error('Freighter is not installed.');
  }
  const { network } = await window.freighter.getNetwork();
  return network;
}

// Expose functions for Flutter JS interop
window.campusCoreFreighter = {
  isInstalled: isFreighterInstalled,
  connect: connectFreighter,
  getPublicKey,
  signTransaction,
  getNetwork,
};
