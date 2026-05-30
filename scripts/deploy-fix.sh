#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# deploy-fix.sh — AutoALEX vulnerability fix deployment
# Adds `claimed-cycles` map and upgrades contract via Clarity's contract-call?
# =============================================================================

# ---- Configuration (overridable via environment) ----
NETWORK="${STACKS_NETWORK:-testnet}"
PRIVATE_KEY="${PRIVATE_KEY:?Must set PRIVATE_KEY}"
DEPLOYER_ADDRESS="${DEPLOYER_ADDRESS:-}"
CONTRACT_SOURCE="./contracts/auto-alex/clar/auto-alex.clar"
UPGRADE_ENTRY="upgrade-claimed-cycles"        # function that migrates state
VERIFY_FUNCTION="get-cycle-claimed"            # read-only to confirm map exists
INTEGRATION_TEST="test/fix-deploy-test.ts"     # post-deployment verification

# ---- Color helpers ----
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ---- Prerequisites ----
command -v clarinet >/dev/null 2>&1 || error "clarinet not found"
command -v jq       >/dev/null 2>&1 || error "jq not found"

# ---- Validate contract file ----
[ -f "$CONTRACT_SOURCE" ] || error "Contract file '$CONTRACT_SOURCE' not found"
grep -q "claimed-cycles" "$CONTRACT_SOURCE" || error "Contract missing 'claimed-cycles' map — apply patch first"

# ---- Derive deployer address ----
if [ -z "$DEPLOYER_ADDRESS" ]; then
    DEPLOYER_ADDRESS=$(clarinet address -n "$NETWORK" -k "$PRIVATE_KEY" 2>/dev/null) \
        || error "Failed to derive deployer address from private key"
fi
info "Deployer: $DEPLOYER_ADDRESS"

# ---- Build & check contract ----
info "Checking contract syntax and invariants…"
clarinet contract check "$CONTRACT_SOURCE" || error "Contract check failed"

# ---- Deploy new contract version ----
CONTRACT_NAME=$(basename "$CONTRACT_SOURCE" .clar)
NEW_CONTRACT_ID="${DEPLOYER_ADDRESS}.${CONTRACT_NAME}"

info "Deploying contract $CONTRACT_NAME to $NETWORK…"
DEPLOY_OUTPUT=$(clarinet deploy -n "$NETWORK" -k "$PRIVATE_KEY" \
    --contract "$CONTRACT_SOURCE" \
    --cost 1000000 2>&1)
echo "$DEPLOY_OUTPUT"

# Extract contract ID from output; fallback to derived ID
EXTRACTED_ID=$(echo "$DEPLOY_OUTPUT" | grep -oP '(?<=Contract deployed at )([^\s]+)' || true)
[ -n "$EXTRACTED_ID" ] && NEW_CONTRACT_ID="$EXTRACTED_ID"
info "New contract ID: $NEW_CONTRACT_ID"

# ---- Call the upgrade function (migration) ----
info "Triggering state migration via $UPGRADE_ENTRY…"
# Get current nonce for deployer
NONCE=$(clarinet get-nonce -n "$NETWORK" -a "$DEPLOYER_ADDRESS" 2>/dev/null || echo "0")

# Construct and send the contract-call transaction
UPGRADE_TX=$(jq -n --arg contract "$NEW_CONTRACT_ID" \
    --arg func "$UPGRADE_ENTRY" \
    --arg nonce "$NONCE" \
    '{
        tx: {
            type: "contract_call",
            contract_identifier: $contract,
            function_name: $func,
            function_args: [],
            nonce: ($nonce | tonumber)
        }
    }')

UPGRADE_RESULT=$(echo "$UPGRADE_TX" | clarinet tx -n "$NETWORK" -k "$PRIVATE_KEY" 2>&1)
echo "$UPGRADE_RESULT"

if echo "$UPGRADE_RESULT" | grep -qiE "(error|abort|revert)"; then
    error "Upgrade transaction failed — migration incomplete"
fi

# ---- Verify the new map is operational ----
info "Verifying '$VERIFY_FUNCTION' on $NEW_CONTRACT_ID…"
VERIFY_RESULT=$(clarinet contract call -n "$NETWORK" -k "$PRIVATE_KEY" \
    -c "$NEW_CONTRACT_ID" \
    -f "$VERIFY_FUNCTION" \
    -a "0" 2>&1) || warn "Verification call failed (function may not be public)"
echo "$VERIFY_RESULT"

# ---- Run post-deployment integration tests ----
if [ -f "$INTEGRATION_TEST" ]; then
    info "Running integration test $INTEGRATION_TEST…"
    clarinet test --test "$INTEGRATION_TEST" 2>&1 || error "Integration test(s) failed"
fi

# ---- Final status ----
info "Deployment completed successfully."
info "Contract: $NEW_CONTRACT_ID"
info "Network:  $NETWORK"