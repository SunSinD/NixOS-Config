#!/usr/bin/env bash
# Dark themed confirmation dialog.
# Usage: confirm.sh "Shut down?" && systemctl poweroff
D=$(mktemp -d)
mkdir -p "$D/gtk-3.0"
cat > "$D/gtk-3.0/gtk.css" << 'EOF'
* {
  background-color: #181825;
  color: #cdd6f4;
  border-color: #313244;
}
window, dialog, messagedialog {
  background-color: #181825;
  border: 1px solid #45475a;
  border-radius: 12px;
}
headerbar {
  background: #181825;
  border: none;
  box-shadow: none;
}
button {
  background: #313244;
  color: #cdd6f4;
  border: 1px solid #45475a;
  border-radius: 8px;
  padding: 8px 24px;
  font-weight: bold;
}
button:hover {
  background: #45475a;
}
label {
  color: #cdd6f4;
  font-weight: bold;
  font-size: 15px;
}
image {
  -gtk-icon-transform: scale(0);
  opacity: 0;
  min-width: 0;
  min-height: 0;
}
EOF

XDG_CONFIG_HOME="$D" zenity --question \
  --title=" " \
  --text="$1" \
  --ok-label="Yes" \
  --cancel-label="No" \
  --width=300 \
  --icon-name="" \
  2>/dev/null
RC=$?
rm -rf "$D"
exit $RC
