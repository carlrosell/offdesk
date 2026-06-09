#!/usr/bin/env bash
#
# One-time setup for Sparkle's EdDSA update-signing keys.
#
#   1. Generates (or reuses) your Sparkle signing keypair in the login Keychain.
#   2. Writes the PUBLIC key into Offdesk/Info.plist (SUPublicEDKey).
#   3. Prints the PRIVATE key so you can paste it into the SPARKLE_PRIVATE_KEY
#      GitHub Actions secret, then deletes the temporary export.
#
# The private key only ever leaves this machine as the value you paste into
# GitHub's encrypted secrets. Treat it like a password — anyone with it can ship
# updates your users will trust. Keychain may prompt you to allow access.
#
# Usage:  scripts/setup-sparkle-keys.sh
#
set -euo pipefail

SPARKLE_VERSION="${SPARKLE_VERSION:-2.9.3}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INFO_PLIST="$REPO_ROOT/Offdesk/Info.plist"

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

echo "==> Downloading Sparkle $SPARKLE_VERSION tools…"
curl -fsSL -o "$workdir/sparkle.tar.xz" \
  "https://github.com/sparkle-project/Sparkle/releases/download/$SPARKLE_VERSION/Sparkle-$SPARKLE_VERSION.tar.xz"
tar -xf "$workdir/sparkle.tar.xz" -C "$workdir"
GEN_KEYS="$workdir/bin/generate_keys"

echo "==> Generating / locating your Sparkle signing key (Keychain may prompt)…"
# Creates a key if none exists; reuses the existing one otherwise.
"$GEN_KEYS" >/dev/null 2>&1 || true
PUBLIC_KEY="$("$GEN_KEYS" -p)"
echo "    Public key: $PUBLIC_KEY"

echo "==> Writing SUPublicEDKey into Offdesk/Info.plist…"
/usr/libexec/PlistBuddy -c "Set :SUPublicEDKey $PUBLIC_KEY" "$INFO_PLIST"

PRIV_FILE="$workdir/sparkle_private_key"
"$GEN_KEYS" -x "$PRIV_FILE" >/dev/null

cat <<'BANNER'

============================================================================
 Add this GitHub Actions secret:
   Settings → Secrets and variables → Actions → New repository secret

   Name:  SPARKLE_PRIVATE_KEY
   Value: (the line between the dashes below)
----------------------------------------------------------------------------
BANNER
cat "$PRIV_FILE"
cat <<'BANNER'
----------------------------------------------------------------------------
 The private-key export above is deleted when this script exits.
 SUPublicEDKey is now set in Offdesk/Info.plist — commit that change.
============================================================================
BANNER
