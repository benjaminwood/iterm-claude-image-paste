#!/bin/sh
# Install the script into iTerm2's AutoLaunch folder.
set -e
DEST="$HOME/Library/Application Support/iTerm2/Scripts/AutoLaunch"
mkdir -p "$DEST"
cp "$(dirname "$0")/claude_image_paste.py" "$DEST/claude_image_paste.py"
echo "Installed to $DEST/claude_image_paste.py"
cat <<'MSG'

Next, in iTerm2:
  1. Settings → General → Magic → enable "Python API".
  2. Scripts → Manage → Install Python Runtime (first time only).
  3. Scripts → AutoLaunch → claude_image_paste.py (or restart iTerm2).
  4. Settings → Keys → Key Bindings → "+":
       Cmd+V   → Invoke Script Function → claude_smart_paste(session_id: id)
       Cmd+⌥V  → Invoke Script Function → claude_image_paste(session_id: id)
MSG
