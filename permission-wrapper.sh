#!/bin/bash
# Wrapper around claude-remote-approver hook.
# Sends a confirmation notification to your phone after you approve a prompt.
#
# Setup: register this script as your PermissionRequest hook in ~/.claude/settings.json
# instead of the claude-remote-approver binary directly.

HOOK="node $(npm root -g)/claude-remote-approver/bin/cli.mjs hook"
CONFIG="$HOME/.claude-remote-approver.json"

# Read stdin into a temp file so we can pipe it to the hook
TMP=$(mktemp)
cat > "$TMP"

# Run the original hook — this sends the prompt to your phone and waits for Approve/Deny
RESULT=$(< "$TMP" $HOOK)
EXIT_CODE=$?
rm -f "$TMP"

# Parse the behavior from the JSON result
BEHAVIOR=$(echo "$RESULT" | node -e "
  let d='';
  process.stdin.on('data', c => d+=c);
  process.stdin.on('end', () => {
    try {
      const r = JSON.parse(d);
      console.log(r.hookSpecificOutput?.decision?.behavior ?? 'ask');
    } catch(e) { console.log('ask'); }
  });
")

# Fire a confirmation notification if approved
if [ "$BEHAVIOR" = "allow" ]; then
  TOPIC=$(node -e "
    const fs = require('fs');
    try {
      const c = JSON.parse(fs.readFileSync('$CONFIG', 'utf8'));
      console.log(c.topic);
    } catch(e) { console.log(''); }
  ")
  if [ -n "$TOPIC" ]; then
    curl -s \
      -H "Title: ✅ Claude is running" \
      -H "Priority: low" \
      -d "Approved — back to coding" \
      "https://ntfy.sh/$TOPIC" > /dev/null &
  fi
fi

# Return the original result to Claude Code unchanged
echo "$RESULT"
exit $EXIT_CODE
