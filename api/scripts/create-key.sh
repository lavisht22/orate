#!/bin/bash
# Creates a new API key and optionally adds initial word balance
# Usage: ./scripts/create-key.sh [words] [--remote]
#
# Examples:
#   ./scripts/create-key.sh              # Create key with 0 balance (local)
#   ./scripts/create-key.sh 10000        # Create key with 10000 words (local)
#   ./scripts/create-key.sh 10000 --remote  # Create key on production

set -e

WORDS=${1:-0}
ENV_FLAG="--local"
if [[ "$2" == "--remote" || "$1" == "--remote" ]]; then
  ENV_FLAG="--remote"
  if [[ "$1" == "--remote" ]]; then
    WORDS=0
  fi
fi

API_KEY="sk-$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 24)"

echo "Creating API key: $API_KEY"
echo "Initial balance: $WORDS words"
echo ""

npx wrangler d1 execute orate-db $ENV_FLAG --command \
  "INSERT INTO keys (api_key, words_remaining) VALUES ('$API_KEY', $WORDS);"

if [ "$WORDS" -gt 0 ]; then
  npx wrangler d1 execute orate-db $ENV_FLAG --command \
    "INSERT INTO recharges (api_key, words_added) VALUES ('$API_KEY', $WORDS);"
fi

echo ""
echo "API key created: $API_KEY"
