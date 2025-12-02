#!/bin/bash
# Copyright 2025 ccorcov
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euo pipefail

# publish output: `sui client publish ... --json > publish_out.json`
JSON_FILE="publish_out.json"
MINT_OUTPUT="mint_out.json"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required. Install jq and retry." >&2
  exit 1
fi

test -f "$JSON_FILE" || { echo "Publish JSON not found: $JSON_FILE"; exit 1; }

# Extract package id from publish output
PACKAGE_ID="$(jq -r '.objectChanges[] | select(.type=="published") | .packageId' "${JSON_FILE}")"
if [[ -z "${PACKAGE_ID}" || "${PACKAGE_ID}" == "null" ]]; then
  echo "Could not find packageId in ${JSON_FILE}" >&2
  exit 1
fi

BRIDGE_MODULE="${PACKAGE_ID}::bridge_nft"
NFT_TYPE="${BRIDGE_MODULE}::BridgeNFT"
COLLECTION_CAP_TYPE="${BRIDGE_MODULE}::CollectionCap"

# Find the shared CollectionCap created during init
COLLECTION_CAP_ID="$(jq -r --arg TYP "${COLLECTION_CAP_TYPE}" '
  .objectChanges[]
  | select(.type=="created" and .objectType==$TYP)
  | .objectId
' "${JSON_FILE}" | head -n1)"

if [[ -z "${COLLECTION_CAP_ID}" || "${COLLECTION_CAP_ID}" == "null" ]]; then
  echo "Could not locate CollectionCap of type ${COLLECTION_CAP_TYPE} in ${JSON_FILE}" >&2
  exit 1
fi

echo "PACKAGE_ID          = $PACKAGE_ID"
echo "BRIDGE_MODULE       = $BRIDGE_MODULE"
echo "COLLECTION_CAP_TYPE = $COLLECTION_CAP_TYPE"
echo "COLLECTION_CAP_ID   = $COLLECTION_CAP_ID"
echo

GAS_BUDGET_DEFAULT=${GAS_BUDGET_DEFAULT:-100000000}

function mint() {
    local NAME="Bridge NFT"
    local IMAGE_URL="https://example.com/bridge.png"
    local GAS="${GAS_BUDGET_DEFAULT}"
    local RECEIVER_ADDRESS="0xeb298a01aef58dce189dbb7d5aa53ea934a14067568ade05b152ab5a8be7df4e"

    sui client call \
        --package "$PACKAGE_ID" \
        --module bridge_nft \
        --function mint \
        --args "$COLLECTION_CAP_ID" "$NAME" "$IMAGE_URL" "$RECEIVER_ADDRESS" \
        --gas-budget "$GAS" \
        --json \
        > "$MINT_OUTPUT"

    echo "TX output saved to $MINT_OUTPUT"

    local NEW_NFT_ID
    NEW_NFT_ID="$(jq -r --arg T "$NFT_TYPE" '
        .objectChanges[] | select(.type=="created" and .objectType==$T) | .objectId
    ' "$MINT_OUTPUT" | head -n1)"

    if [[ -n "$NEW_NFT_ID" && "$NEW_NFT_ID" != "null" ]]; then
        echo "Minted BridgeNFT id: $NEW_NFT_ID"
    else
        echo "Mint done (NFT may have merged). Inspect $MINT_OUTPUT."
    fi
}

# This script takes in a function name as the first argument,
# and runs it in the context of the script.
if [ -z "${1:-}" ]; then
  echo "Usage: bash script.sh <function> [args...]"
  exit 1
elif declare -f "$1" > /dev/null; then
  "$@"
else
  echo "Function '$1' does not exist"
  exit 1
fi
