set -euo pipefail
niri_bin=/run/current-system/sw/bin/niri
if [[ ! -x "$niri_bin" ]]; then
  niri_bin="$(command -v niri 2>/dev/null || true)"
fi
[[ -n "$niri_bin" ]] || { echo "niri not found" >&2; exit 1; }
pattern="${1?}"
shift
id="$("$niri_bin" msg --json windows | @JQ@ -r --arg p "$pattern" -f @FILTER@)"
if [[ -n "$id" && "$id" != "null" ]]; then
  exec "$niri_bin" msg action focus-window "$id"
else
  exec "$@"
fi
