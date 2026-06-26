#!/usr/bin/env bash
# DroneHub GCS — set Crowdin personal token locally (~/.zshrc) and on GitHub Actions.
# Usage: ./tools/crowdin-setup-secrets.sh <token>
#    or: CROWDIN_PERSONAL_TOKEN=... ./tools/crowdin-setup-secrets.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="${GITHUB_REPOSITORY:-demna63/DroneHub-GCS}"
ZSHRC="${HOME}/.zshrc"
PROJECT_ID="${CROWDIN_PROJECT_ID:-909155}"

TOKEN="${1:-${CROWDIN_PERSONAL_TOKEN:-}}"
if [ -z "$TOKEN" ]; then
  echo "Usage: $0 <crowdin-personal-access-token>" >&2
  echo "   or: CROWDIN_PERSONAL_TOKEN=... $0" >&2
  exit 1
fi

mask_token() {
  local t="$1"
  local n=${#t}
  if [ "$n" -le 8 ]; then
    echo '****'
  else
    echo "${t:0:4}…${t: -4} (len=$n)"
  fi
}

echo "Setting GitHub secret CROWDIN_PERSONAL_TOKEN for ${REPO} (token: $(mask_token "$TOKEN"))"
if ! command -v gh >/dev/null 2>&1; then
  echo "!! gh CLI not found; skip GitHub secret or install gh" >&2
  exit 1
fi
gh secret set CROWDIN_PERSONAL_TOKEN --body "$TOKEN" --repo "$REPO"
gh secret set CROWDIN_PROJECT_ID --body "$PROJECT_ID" --repo "$REPO" 2>/dev/null || true

touch "$ZSHRC"
# Remove prior CROWDIN_PERSONAL_TOKEN export lines (keep comments/project id block)
grep -v '^export CROWDIN_PERSONAL_TOKEN=' "$ZSHRC" > "${ZSHRC}.crowdin.tmp" || true
mv "${ZSHRC}.crowdin.tmp" "$ZSHRC"

if ! grep -q 'export CROWDIN_PROJECT_ID=' "$ZSHRC" 2>/dev/null; then
  cat >> "$ZSHRC" << EOF

# DroneHub GCS — Crowdin (see tools/CROWDIN.md)
export CROWDIN_PROJECT_ID="${PROJECT_ID}"
EOF
fi

# Ensure token export after project id block (or append)
if grep -q 'export CROWDIN_PROJECT_ID=' "$ZSHRC"; then
  awk -v tok="$TOKEN" '
    /^export CROWDIN_PROJECT_ID=/ { print; print "export CROWDIN_PERSONAL_TOKEN=\"" tok "\""; skip=1; next }
    /^export CROWDIN_PERSONAL_TOKEN=/ { skip=1; next }
    { if (!skip) print }
  ' "$ZSHRC" > "${ZSHRC}.crowdin.tmp"
  mv "${ZSHRC}.crowdin.tmp" "$ZSHRC"
else
  echo "export CROWDIN_PERSONAL_TOKEN=\"${TOKEN}\"" >> "$ZSHRC"
fi

export CROWDIN_PROJECT_ID="$PROJECT_ID"
export CROWDIN_PERSONAL_TOKEN="$TOKEN"

CROWDIN_BIN="${CROWDIN_BIN:-${HOME}/.nvm/versions/node/v22.23.0/bin/crowdin}"
if [ ! -x "$CROWDIN_BIN" ]; then
  CROWDIN_BIN="$(command -v crowdin || true)"
fi
if [ -z "$CROWDIN_BIN" ] || [ ! -x "$CROWDIN_BIN" ]; then
  echo "!! crowdin CLI not found; secrets updated but cannot run crowdin status" >&2
  exit 0
fi

echo "Verifying Crowdin API (crowdin status) from ${ROOT}…"
if ! (cd "$ROOT" && "$CROWDIN_BIN" status); then
  echo "!! crowdin status failed — check token scopes (Projects Read+Write) and project ID ${PROJECT_ID}" >&2
  exit 1
fi

echo "Done. Token set in GitHub Actions and ~/.zshrc (not printed). Run: source ~/.zshrc"
