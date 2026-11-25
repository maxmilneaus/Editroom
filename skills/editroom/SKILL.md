---
name: editroom
description: Edit video in Editroom, the Mac video editor, through its own tools. Use when asked to cut, trim, grade, caption, add music to, reframe or export a video in Editroom, or to connect an agent to Editroom.
---

# Editroom

Editroom is a video editor on this Mac. It gives agents its editing tools over MCP (the Model Context Protocol). Once connected, Editroom sends your agent a short guide and a description of every tool, so this skill covers only what that doesn't: getting connected, and a few house rules.

**Edit only through Editroom's tools.** Don't drive its window with screenshots, clicks, computer use or AppleScript. The tools see the exact project; the window doesn't.

## Connect

Look in your tool list first. Editroom's tools are named like `mcp__editroom__get_project` or `editroom.get_project`. If they're there, you're connected: skip to House rules.

If not, run `scripts/connect.sh` (paths are relative to this skill's folder). It finds Editroom, says which agents on this Mac are connected, and gives the command for yours:

| Agent | Connect with |
| --- | --- |
| Claude app, ChatGPT/Codex, Claude Code | One click: Editroom › Settings › Magic › AI apps |
| Codex CLI | `scripts/connect.sh codex` |
| Claude Code | `scripts/connect.sh claude-code` |
| Hermes | `scripts/connect.sh hermes` |
| Anything else | `scripts/connect.sh json`, `toml` or `yaml`, then paste into its MCP settings |

Agents load their tools when a session starts, so start a new session after connecting.

Until then, call the same tools from the shell. Editroom must be open:

```sh
scripts/call.sh tools                                  # each tool and its argument names
scripts/call.sh get_project
scripts/call.sh set_marker '{"time": 2, "name": "Intro"}'
scripts/call.sh history '{"action": "undo"}'
```

It prints the reply (pictures are saved, and their paths printed) and exits 1 on an error.

The connection is Editroom's own launcher, `Editroom.app/Contents/MacOS/Editroom --mcp`. It opens Editroom on the first real request and reconnects if Editroom quits and reopens. Quit Editroom normally to restart it: `pkill Editroom` also kills every agent's launcher, and those agents lose the tools until a new session.

## House rules

- **Ask first** before `auto_edit` (replaces the timeline), `save_project` and `export` (write files), and `download_media` (fetches from the internet).
- **Check each change** with `get_project`. `history` replies only with a clip count.
- **Titles and solids overwrite too.** Like clips, anything placed over something on the same track replaces it. Find a free stretch, or `add_track`.
- **Picture fades** (titles, photos, solids) are set with `set_audio`'s `fade_in` and `fade_out`.

## Spend fewer tokens

Each request resends the conversation so far.

- Work in one session per video, so you keep what you've learned about the footage.
- Prefer `search_media`, transcripts and saved notes over `look_at_media`, which sends pictures.
- Use low reasoning effort for routine cuts, and a small model when it's enough.

