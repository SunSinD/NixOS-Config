#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="$HOME/nixconf/modules/apps/niri/bar-state.kdl"

write_bar_state() {
  local top="$1"
  local tmp

  mkdir -p "$(dirname "$STATE_FILE")"
  tmp="$(mktemp "${STATE_FILE}.XXXXXX")"
  cat > "$tmp" << EOF
layout {
    struts {
        top $top
    }
}
EOF
  mv "$tmp" "$STATE_FILE"
}

if grep -q 'top 52' "$STATE_FILE" 2>/dev/null; then
  noctalia-shell ipc call bar toggle >/dev/null 2>&1 || true
  sleep 0.08
  write_bar_state 0
else
  write_bar_state 52
  sleep 0.08
  noctalia-shell ipc call bar toggle >/dev/null 2>&1 || true
fi
