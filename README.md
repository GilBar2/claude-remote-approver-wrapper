# claude-remote-approver-wrapper

A wrapper script for [claude-remote-approver](https://github.com/yuuichieguchi/claude-remote-approver) that fires a **confirmation notification to your phone** the moment you tap Approve on a Claude Code permission prompt.

## How it works

1. Claude Code triggers a `PermissionRequest` hook
2. The wrapper pipes the payload to `claude-remote-approver` — which sends an Approve/Deny notification to your phone via [ntfy.sh](https://ntfy.sh)
3. You tap **Approve** on your phone
4. The wrapper detects `behavior === "allow"` and immediately fires a second ntfy notification: **"✅ Claude is running — Approved, back to coding"**
5. The original JSON result is returned to Claude Code unchanged

The second notification closes the loop — you know Claude got the green light without checking your screen again.

## vs. Anthropic's Dispatch

- **What ntfy is:** [ntfy.sh](https://ntfy.sh) is a free, open-source push notification service. Subscribe to a topic on your phone, and anything published to that topic shows up as a notification. This wrapper uses it to send Approve/Deny prompts (and confirmations) to your phone.
- **Dispatch**, Anthropic's built-in feature for running Claude Code tasks in the cloud, unattended:
  - Runs pre-authorized in a sandbox, no local file access, so nothing needs approval.
  - Best for long jobs that don't need your machine.
- **This wrapper** runs entirely on your own machine, with full access to your files and tools:
  - Routes each risky action to your phone via ntfy for a real Approve/Deny before it happens.
  - Best for tasks that need your local setup, but you still want to step away from the keyboard.
- **Bottom line:** Dispatch when the task doesn't need your machine. This wrapper when it does.

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
  "topic": "your-ntfy-topic-here",
  "ntfyServer": "https://ntfy.sh",
  "timeout": 600,
  "planTimeout": 600,
  "autoApprove": [],
  "autoDeny": []
}
```

| Key | Description | Default |
|-----|-------------|---------|
| `topic` | Your ntfy topic ID (from `claude-remote-approver setup`) | required |
| `ntfyServer` | ntfy server URL | `https://ntfy.sh` |
| `timeout` | Seconds to wait for your tap before falling back to terminal | `600` |
| `planTimeout` | Same, for plan-mode prompts | `600` |
| `autoApprove` | Tool patterns to approve silently without notification | `[]` |
| `autoDeny` | Tool patterns to deny silently without notification | `[]` |

**Timeout guidance:** 600s (10 min) is a practical maximum. If you miss the notification, Claude Code is frozen until the timeout expires — shorter = faster fallback.

See `.claude-remote-approver.json.example` in this repo.

## Why ntfy over the native Claude iOS app?

Claude Code v2.1.110+ supports native push notifications to the Claude iOS app via Remote Control. Here's why you might still prefer ntfy for permission approvals:

### 1. No action buttons in the native notification

ntfy pushes arrive with **Approve / Deny tappable buttons** — you never open an app, just tap the notification. Native Claude iOS push says "Claude needs a decision" → you have to unlock phone → open Claude app → find the session → respond. That's ~5 steps vs 1.

### 2. Permission prompts are terminal UI, not chat

Claude Code's permission prompts are interactive keypresses (`y`/`n`/`a`). How well they render in the Remote Control chat interface is untested. It may work fine, or it may be awkward.

### 3. Timeout risk

The ntfy hook waits up to `timeout` seconds for your tap. With ntfy buttons you respond in seconds without opening anything; with the native app you'd need to open it and navigate to the session.

### 4. "Always allow" is harder natively

With ntfy, the `autoApprove` list in `~/.claude-remote-approver.json` handles persistent always-allow rules. Native iOS doesn't give you that — you'd have to respond every time for the same tool.

> **Recommended setup:** use both. ntfy handles permission approvals with one-tap buttons; Claude iOS Remote Control handles task-complete notifications and session control. Two apps, two purposes.

## Recommended setup: ntfy + Remote Control

For the full remote workflow, add these keys to `~/.claude/settings.json`:

```json
{
  "remoteControlAtStartup": true,
  "inputNeededNotifEnabled": true,
  "agentPushNotifEnabled": true
}
```

With these set, every `claude` session auto-registers in the Claude iOS app — no `--remote-control` flag needed. Combined with the ntfy hook above, you get one-tap permission approvals via ntfy plus task-complete and decision pushes via the native Claude iOS app.

**Requires:** Claude Code v2.1.110+, a Pro/Max/Team/Enterprise plan, and the Claude iOS app signed into the same account.

## Credits

- [claude-remote-approver](https://github.com/yuuichieguchi/claude-remote-approver) by Yuuichi Eguchi — does all the heavy lifting (SSE long-poll, Approve/Deny buttons, timeout fallback)
- This wrapper adds the confirmation notification on top

## License

MIT
