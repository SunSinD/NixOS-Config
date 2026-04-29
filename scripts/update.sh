#!/usr/bin/env bash
# Clean system update — syncs with GitHub and rebuilds.
cd ~/nixconf || exit 1

printf '\n  \033[1mSyncing...\033[0m\n'
git fetch -q origin && git reset -q --hard origin/main

printf '  \033[1mBuilding...\033[0m  (this may take a moment)\n\n'
sudo nixos-rebuild switch --flake ~/nixconf#"$(hostname)" > /tmp/_build.log 2>&1
RC=$?

if [ $RC -eq 0 ]; then
  printf '  \033[1;32m✓ Updated!\033[0m  Reboot to apply all changes.\n\n'
else
  printf '  \033[1;31m✗ Failed:\033[0m\n\n'
  grep -i 'error' /tmp/_build.log | head -8
  printf '\n'
fi
rm -f /tmp/_build.log
