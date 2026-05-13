#!/bin/bash
# Recharges an existing API key with additional words
# Usage: ./scripts/recharge-key.sh <api_key> <words> [--remote]
#
# Examples:
#   ./scripts/recharge-key.sh abc-123 5000          # Add 5000 words (local)
#   ./scripts/recharge-key.sh abc-123 5000 --remote # Add 5000 words (production)

set -e

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: ./scripts/recharge-key.sh <api_key> <words> [--remote]"
  exit 1
fi

API_KEY=$1
WORDS=$2
ENV_FLAG="--local"
if [[ "$3" == "--remote" ]]; then
  ENV_FLAG="--remote"
fi

echo "Recharging key: $API_KEY"
echo "Adding: $WORDS words"
echo ""

npx wrangler d1 execute orate-db $ENV_FLAG --command \
  "UPDATE keys SET words_remaining = words_remaining + $WORDS WHERE api_key = '$API_KEY';"

npx wrangler d1 execute orate-db $ENV_FLAG --command \
  "INSERT INTO recharges (api_key, words_added) VALUES ('$API_KEY', $WORDS);"

BALANCE=$(npx wrangler d1 execute orate-db $ENV_FLAG --command \
  "SELECT words_remaining FROM keys WHERE api_key = '$API_KEY';" --json 2>/dev/null | grep -o '"words_remaining":[0-9]*' | head -1 | cut -d: -f2)

echo ""
echo "Recharge complete. New balance: ${BALANCE:-unknown} words"
