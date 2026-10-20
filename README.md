# Claude Code: Image Paste (bracketed) — iTerm2

Paste a clipboard image into **Claude Code running over SSH in iTerm2** and have Claude render it inline as `[Image N]`. This is the same result as [cmux](https://cmux.com) and the VS Code extension [`claude-image-paste-bracketed`](https://marketplace.visualstudio.com/items?itemName=benjaminwood.claude-image-paste-bracketed), using an iTerm2 Python API script.

## Why this works

Claude Code turns a pasted path into an image attachment only when **all** of these hold:

1. The bytes arrive as a *bracketed paste*, wrapped in `ESC[200~ … ESC[201~`. The image-path detector lives inside Claude's paste handler, so typed input never reaches it.
2. The whole (trimmed) payload is a path matching `/\.(png|jpe?g|gif|webp)$/i`.
3. The path resolves to a readable file **on the machine Claude runs on** (the remote).

| | VS Code extension | This script |
|---|---|---|
| Read local clipboard | AppleScript `«class PNGf»`, TIFF→`sips` fallback | same |
| Get the file to the remote (3) | `vscode.workspace.fs` over Remote-SSH | re-uses the focused session's own `ssh` command line and streams the PNG with `cat >` |
| Bracketed-paste the path (1, 2) | `workbench.action.terminal.sendSequence` | `session.async_send_text("\e[200~<path>\e[201~")` |
| Text still pastes normally | in-process `readText()` → built-in paste | `pbpaste` check → iTerm's own **Edit → Paste** |

### Finding the remote

When you press the key, the script looks at the focused session's tty and finds the `ssh` client running in the foreground. It reads that client's exact argv with `sysctl(KERN_PROCARGS2)`, so the host alias, `-p`, `-i`, `-J`, `-o ProxyCommand …` and everything else carry over. Then it runs:

```
ssh <your options> -T -o BatchMode=yes -o ClearAllForwardings=yes <host> \
  'write stdin to ~/.claude-images/clipboard-<ts>-<rand>.png; print path; prune > 7 days'
```

This is one round trip. If the session isn't running `ssh` (Claude is local), the image is written to `~/.claude-images` on your Mac instead.

## Strongly recommended: SSH connection sharing

The upload is a second SSH connection. With `BatchMode=yes` it never prompts, so if your login needs a password or 2FA, the upload fails. You'll see a notification telling you so. Turn on multiplexing so the upload reuses your existing connection, which is instant and needs no new auth:

```sshconfig
# ~/.ssh/config
Host *
  ControlMaster auto
  ControlPath ~/.ssh/cm-%C
  ControlPersist 10m
```

Key or agent auth also works without this, but ControlMaster makes each paste noticeably faster.

## Install

```sh
./install.sh
```

Then in iTerm2:

1. **Settings → General → Magic → Enable Python API.**
2. **Scripts → Manage → Install Python Runtime** (first time only).
3. **Scripts → AutoLaunch → claude_image_paste.py**, or restart iTerm2.
4. **Settings → Keys → Key Bindings → +**:

| Shortcut | Action | Function call |
|---|---|---|
| `⌘V` | Invoke Script Function | `claude_smart_paste(session_id: id)` |
| `⌘⌥V` | Invoke Script Function | `claude_image_paste(session_id: id)` |

## Usage

1. `ssh devbox`, then run `claude`.
2. Copy an image or take a screenshot to the clipboard (`⌘⌃⇧4`).
3. Press **`⌘V`**. Claude shows `[Image N]`.

`⌘V` is a smart dispatcher. When the clipboard has **text**, it hands off to iTerm's normal Paste, so paste warnings and the rest behave as before. Only when there's **no text but an image** does it run the image flow. `⌘⌥V` always forces image mode.

## Settings

Edit the constants at the top of `claude_image_paste.py` and re-run `./install.sh`:

| Constant | Default | Description |
|---|---|---|
| `IMAGE_DIRECTORY` | `.claude-images` | Directory under `$HOME` (remote or local) for pasted images. |
| `INSERTION_MODE` | `bracketedPaste` | `plain` types the bare path. Use it only for A/B debugging. |
| `CLEANUP_AFTER_DAYS` | `7` | Prune older pasted images (0 = never). |
| `UPLOAD_TIMEOUT_S` | `20` | Give up on the upload after this many seconds. |

## Limitations

- **Local tmux wrapping ssh** (`tmux` on your Mac, `ssh` inside it): the session's foreground process is the tmux client, not ssh, so the image is written locally. tmux on the *remote* works fine.
- **iTerm2 tmux integration (`tmux -CC`)** is untested. Those sessions have no local pty to inspect.
- Only plain `ssh`. `mosh`, `et`, `kubectl exec` and `gcloud compute ssh` wrappers aren't detected.
- The remote needs a POSIX `sh`, `mkdir`, `cat` and `find`.

## License

MIT
