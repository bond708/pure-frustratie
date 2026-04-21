#!/usr/bin/env bash
#
# Deploy pure-frustratie naar TransIP shared hosting.
#
# Vereist:
#   - SSH-sleutel ~/.ssh/id_ed25519_pure-frustratie_deploy
#   - Werktree schoon en commits gepusht naar origin/main
#
# Gebruik:
#   ./scripts/deploy.sh
#

set -euo pipefail

readonly SSH_HOST='dvborg.ssh.transip.me'
readonly SSH_USER='dvborgercompagnienl'
readonly SSH_KEY="$HOME/.ssh/id_ed25519_pure-frustratie_deploy"
readonly REMOTE_PATH='/data/sites/web/dvborgercompagnienl/subsites/pure-frustratie.nl'

# ── Kleuren voor leesbare output ─────────────────────────────────────────────
readonly CYAN='\033[0;36m'
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

step()    { printf '\n%b▶ %s%b\n' "$CYAN" "$*" "$NC"; }
success() { printf '%b✓ %s%b\n' "$GREEN" "$*" "$NC"; }
warn()    { printf '%b⚠ %s%b\n' "$YELLOW" "$*" "$NC"; }
fail()    { printf '%b✗ %s%b\n' "$RED" "$*" "$NC" >&2; exit 1; }

# ── Pre-flight checks ────────────────────────────────────────────────────────

[[ -f "$SSH_KEY" ]] || fail "SSH-sleutel niet gevonden: $SSH_KEY"

cd "$(dirname "$0")/.."

if [[ -n "$(git status --porcelain)" ]]; then
  warn "Er zijn ongecommite wijzigingen:"
  git status --short
  read -r -p "Toch doorgaan? (y/N) " reply
  [[ "$reply" =~ ^[Yy]$ ]] || fail "Afgebroken."
fi

readonly LOCAL_SHA="$(git rev-parse HEAD)"
readonly REMOTE_SHA="$(git rev-parse @{u} 2>/dev/null || echo '')"

if [[ "$LOCAL_SHA" != "$REMOTE_SHA" ]]; then
  warn "Lokale HEAD verschilt van origin/main."
  read -r -p "Eerst pushen? (Y/n) " reply
  if [[ ! "$reply" =~ ^[Nn]$ ]]; then
    step "git push"
    git push origin main
  fi
fi

# ── Remote deploy ────────────────────────────────────────────────────────────

step "Verbinden met $SSH_HOST en deployen"

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=accept-new \
  "$SSH_USER@$SSH_HOST" bash <<REMOTE
set -euo pipefail
cd "$REMOTE_PATH"

echo "▶ git pull"
git pull origin main

echo "▶ composer install"
composer install --no-dev --optimize-autoloader --no-interaction

echo "▶ drush updb"
vendor/bin/drush updb -y

echo "▶ drush cim"
vendor/bin/drush cim -y

echo "▶ drush cr"
vendor/bin/drush cr

echo "▶ Huidige versie:"
git log -1 --oneline
REMOTE

success "Deploy voltooid."
