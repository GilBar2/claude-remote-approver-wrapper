# claude-remote-approver-wrapper

A wrapper script for [claude-remote-approver](https://github.com/yuuichieguchi/claude-remote-approver) that fires a **confirmation notification to your phone** the moment you tap Approve on a Claude Code permission prompt.

## How it works

1. Claude Code triggers a `PermissionRequest` hook
2. The wrapper pipes the payload to `claude-remote-approver` — which sends an Approve/Deny notification to your phone via [ntfy.sh](https://ntfy.sh)
3. You tap **Approve** on your phone
4. The wrapper detects `behavior === "allow"` and immediately fires a second ntfy notification: **"✅ Claude is running — Approved, back to coding"**
5. The original JSON result is returned to Claude Code unchanged

The second notification closes the loop — you know Claude got the green light without checking your screen again.

## Prerequisites

- [claude-remote-approver](https://github.com/yuuichieguchi/claude-remote-approver) installed globally:
  ```bash
  npm install -g claude-remote-approver
  ```
- [ntfy](https://ntfy.sh) app on your phone, subscribed to your topic
- `curl` and `node` available in your shell

## Setup

### 1. Run the claude-remote-approver setup

```bash
claude-remote-approver setup
```

Follow the prompts — it creates `~/.claude-remote-approver.json` with your ntfy topic.

### 2. Install the wrapper

```bash
mkdir -p ~/.claude/hooks
cp permission-wrapper.sh ~/.claude/hooks/permission-wrapper.sh
chmod +x ~/.claude/hooks/permission-wrapper.sh
```

### 3. Register the wrapper as your PermissionRequest hook

In `~/.claude/settings.json`, add (or update) the hooks section:

```json
{
  "hooks": {
    "PermissionRequest": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/Users/YOUR_USERNAME/.claude/hooks/permission-wrapper.sh"
          }
        ]
      }
    ]
  }
}
```

Replace `YOUR_USERNAME` with your actual macOS username.

> **Important:** Point the hook at this wrapper, not at the `claude-remote-approver` binary directly.

### 4. Test the notification

Fire a test curl to confirm your ntfy topic is working:

```bash
TOPIC=$(node -e "const c=require(process.env.HOME+'/.claude-remote-approver.json');console.log(c.topic)")
curl -H "Title: ✅ Claude is running" -H "Priority: low" \
  -d "Approved — back to coding" "https://ntfy.sh/$TOPIC"
```

You should see the notification on your phone immediately.

### 5. End-to-end test

Start a fresh Claude Code session, trigger any permission prompt, tap **Approve** on your phone — the confirmation notification should arrive within a second or two.

## Config

`~/.claude-remote-approver.json`:
```json
{
  "topic": "your-ntfy-topic-here"
}
```

See `.claude-remote-approver.json.example` in this repo.

## Why ntfy over the native Claude iOS app?

Claude Code v2.1.110+ supports native push notifications to the Claude iOS app via Remote Control. Here's why you might still prefer ntfy for permission approvals:

### 1. No action buttons in the native notification

ntfy pushes arrive with **Approve / Deny tappable buttons** — you never open an app, just tap the notification. Native Claude iOS push says "Claude needs a decision" → you have to unlock phone → open Claude app → find the session → respond. That's ~5 steps vs 1.

### 2. Permission prompts are terminal UI, not chat

Claude Code's permission prompts are interactive keypresses (`y`/`n`/`a`). How well they render in the Remote Control chat interface is untested. It may work fine, or it may be awkward.

### 3. Timeout risk

The ntfy hook has a 120s window. If you're slow to open the Claude app, the prompt times out and falls back to the terminal. With ntfy buttons, you respond in seconds without opening anything.

### 4. "Always allow" is harder natively

With ntfy, the `autoApprove` list in `~/.claude-remote-approver.json` handles persistent always-allow rules. Native iOS doesn't give you that — you'd have to respond every time for the same tool.

> **Recommended setup:** use both. ntfy handles permission approvals with one-tap buttons; Claude iOS Remote Control handles task-complete notifications and session control. Two apps, two purposes.

## Credits

- [claude-remote-approver](https://github.com/yuuichieguchi/claude-remote-approver) by Yuuichi Eguchi — does all the heavy lifting (SSE long-poll, Approve/Deny buttons, timeout fallback)
- This wrapper adds the confirmation notification on top

## License

MIT
