#!/usr/bin/env bash
# Clean system update with progress phases.
cd ~/nixconf || exit 1

# ── Phase 1: Sync ────────────────────────────────────────
printf '\n\033[1;34m  ⟳ Syncing with GitHub...\033[0m\n'
git fetch -q origin && git reset -q --hard origin/main
printf '\033[1;32m  ✓ Synced\033[0m\n\n'

# ── Phase 2: Build ───────────────────────────────────────
printf '\033[1;34m  ⟳ Building system...\033[0m\n'
sudo nixos-rebuild switch --flake ~/nixconf#"$(hostname)" 2>&1 | while IFS= read -r line; do
  # Show build progress (derivation names, cleaned up)
  if [[ "$line" == *"building '"* ]]; then
    name=$(echo "$line" | sed "s|.*building '/nix/store/[^-]*-||;s|\.drv.*||")
    printf '    → %s\n' "$name"
  # Show activation steps
  elif [[ "$line" == "activating the configuration"* ]]; then
    printf '\n\033[1;34m  ⟳ Activating...\033[0m\n'
  elif [[ "$line" == "setting up"* || "$line" == "reloading"* || "$line" == "restarting"* ]]; then
    printf '    → %s\n' "$line"
  elif [[ "$line" == "Done."* ]]; then
    printf '    → %s\n' "$line"
  # Show real errors
  elif [[ "$line" == *"error:"* ]]; then
    printf '\033[1;31m  ✗ %s\033[0m\n' "$line"
  fi
done

RC=${PIPESTATUS[0]}
if [ "$RC" -eq 0 ]; then
  printf '\n\033[1;32m  ✓ Updated!\033[0m  Reboot to apply all changes.\n\n'
else
  printf '\n\033[1;31m  ✗ Build failed.\033[0m  Run "sudo nixos-rebuild switch --flake ~/nixconf#vm --show-trace" for details.\n\n'
fi
