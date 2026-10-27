set -euo pipefail
niri_bin=/run/current-system/sw/bin/niri
if [[ ! -x "$niri_bin" ]]; then
  niri_bin="$(command -v niri 2>/dev/null || true)"
fi
[[ -n "$niri_bin" ]] || { echo "niri not found" >&2; exit 1; }
pattern="${1?}"
shift
# If niri's JSON output format changes or msg fails, don't break hotkeys — just spawn.
id="$("$niri_bin" msg --json windows 2>/dev/null | @JQ@ -r --arg p "$pattern" -f @FILTER@ 2>/dev/null || true)"
if [[ -n "$id" && "$id" != "null" ]]; then
  exec "$niri_bin" msg action focus-window "$id"
else
  exec "$@"
fi
