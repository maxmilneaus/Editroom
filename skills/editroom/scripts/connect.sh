#!/bin/sh
# Connects an agent to Editroom's tools. Usage: connect.sh [check|codex|claude-code|hermes|json|toml|yaml]
set -eu
id=com.wonderassembly.Editroom
app=/Applications/Editroom.app
[ -d "$app" ] || app=$(/usr/bin/mdfind "kMDItemCFBundleIdentifier == '$id'" | /usr/bin/head -n 1)
bin="$app/Contents/MacOS/Editroom"

need_app() { [ -x "$bin" ] || { echo "Editroom isn't installed. Get it from https://github.com/robbietilton/Editroom/releases/latest"; exit 1; }; }
has() { command -v "$1" >/dev/null 2>&1; }
# The launcher path as a JSON string (also valid YAML and TOML).
quoted() { /usr/bin/python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$bin"; }

check() {
  # The usual port, or whichever one a running copy took (last field after the final colon, so IPv6 works too).
  for port in 47920 $(/usr/sbin/lsof -nP -a -iTCP -sTCP:LISTEN -c Editroom 2>/dev/null | /usr/bin/awk 'NR>1{n=split($9,a,":");print a[n]}'); do
    reply=$(/usr/bin/curl -s -m 3 -X POST "http://127.0.0.1:$port/mcp" -H 'Content-Type: application/json' \
      -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"connect.sh","version":"1"}}}' || true)
    case "$reply" in *editroom*) echo "Editroom is answering at http://127.0.0.1:$port/mcp"; return 0;; esac
  done
  echo "Editroom isn't open. Agents connected with this script open it on their first request."
}

hermes_has() { hermes mcp list 2>/dev/null | /usr/bin/awk '$1=="editroom"{f=1} END{exit !f}'; }

status() {
  need_app
  echo "Editroom: $app"
  check
  if has codex; then codex mcp get editroom >/dev/null 2>&1 && echo "codex: connected" || echo "codex: not connected  -> connect.sh codex"; fi
  if has claude; then claude mcp get editroom >/dev/null 2>&1 && echo "claude-code: connected" || echo "claude-code: not connected  -> connect.sh claude-code"; fi
  if has hermes; then hermes_has && echo "hermes: connected" || echo "hermes: not connected  -> connect.sh hermes"; fi
  echo "Claude app: Editroom > Settings > Magic > Claude > Connect"
  echo "Other agents: connect.sh json | toml | yaml"
  echo "No tools in this session yet: scripts/call.sh tools"
}

what=status
[ $# -gt 0 ] && what=$1
case "$what" in
  status) status ;;
  check) check ;;
  codex)
    need_app
    codex mcp get editroom >/dev/null 2>&1 && { echo "codex: already connected"; exit 0; }
    codex mcp add editroom -- "$bin" --mcp --from codex && echo "codex: connected. Start a new session." ;;
  claude-code)
    need_app
    claude mcp get editroom >/dev/null 2>&1 && { echo "claude-code: already connected"; exit 0; }
    claude mcp add --scope user editroom -- "$bin" --mcp --from claude-code && echo "claude-code: connected. Start a new session." ;;
  hermes)
    need_app
    hermes_has && { echo "hermes: already connected"; exit 0; }
    yes | hermes mcp add editroom --command "$bin" --args --mcp --from hermes >/dev/null && echo "hermes: connected. Start a new session." ;;
  json) need_app; printf '{"mcpServers":{"editroom":{"command":%s,"args":["--mcp"]}}}\n' "$(quoted)" ;;
  toml) need_app; printf '[mcp_servers.editroom]\ncommand = %s\nargs = ["--mcp"]\ntool_timeout_sec = 300\n' "$(quoted)" ;;
  yaml) need_app; printf 'mcp_servers:\n  editroom:\n    command: %s\n    args: ["--mcp"]\n' "$(quoted)" ;;
  *) echo "Usage: connect.sh [check|codex|claude-code|hermes|json|toml|yaml]"; exit 2 ;;
esac

