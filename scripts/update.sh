#!/usr/bin/env bash
# update.sh — `update` alias.
#
# Pulls the latest config from GitHub and rebuilds the system.
# The secure-boot toggle is read BEFORE the reset so a `git reset --hard`
# can't accidentally turn Secure Boot off; we restore the saved value after.

cd ~/nixconf || exit 1

# Snapshot the local Secure Boot state (if any) before overwriting the tree.
SECURE_BOOT_STATE=""
if [ -f modules/nixos/secure-boot-state.json ]; then
  SECURE_BOOT_STATE="$(cat modules/nixos/secure-boot-state.json)"
fi

# ── Phase 1: Sync with GitHub ────────────────────────────────────────────────
echo ""
echo "  Syncing with GitHub..."
git fetch -q origin && git reset -q --hard origin/main
# Restore the saved Secure Boot state.
if [ -n "$SECURE_BOOT_STATE" ]; then
  printf '%s\n' "$SECURE_BOOT_STATE" > modules/nixos/secure-boot-state.json
fi
echo "  Done."
echo ""

# ── Phase 2: Rebuild ─────────────────────────────────────────────────────────
# The `while read` loop filters nixos-rebuild's noisy output down to a few
# friendly lines: which package is building, then activation events.
echo "  Building system..."
echo ""
sudo nixos-rebuild switch \
  --option fallback true \
  --option download-attempts 5 \
  --option connect-timeout 20 \
  --flake ~/nixconf#"$(hostname)" 2>&1 | while IFS= read -r line; do
  if [[ "$line" == *"building '"* ]]; then
    name=$(echo "$line" | sed "s|.*building '/nix/store/[^-]*-||;s|\.drv.*||")
    echo "    building $name..."
  elif [[ "$line" == "activating the configuration"* ]]; then
    echo ""
    echo "  Activating..."
    echo ""
  elif [[ "$line" == "setting up"* || "$line" == "reloading"* || "$line" == "restarting"* || "$line" == "the following"* ]]; then
    echo "    $line"
  elif [[ "$line" == "Done."* ]]; then
    echo "    $line"
  elif [[ "$line" == *"error:"* ]]; then
    echo "    ERROR: $line"
  fi
done

RC=${PIPESTATUS[0]}
echo ""
if [ "$RC" -eq 0 ]; then
  echo "  System updated. Reboot to apply changes."
else
  echo "  Build failed. Run 'sudo nixos-rebuild switch --flake ~/nixconf#$(hostname) --show-trace' for details."
fi
echo ""
