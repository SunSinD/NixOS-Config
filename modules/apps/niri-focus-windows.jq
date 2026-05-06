[.Ok.Windows[]? | select(.app_id != null and (.app_id | test($p)))] | sort_by(.id) | .[-1].id // empty
