#!/bin/sh
# Calls one Editroom tool over MCP, for agents whose session hasn't loaded Editroom's tools.
# Usage: call.sh <tool> ['{"json":"arguments"}']    call.sh tools    (each tool and its argument names)
# Prints the tool's text reply; pictures (get_frame, look_at_media) are saved and their paths printed.
# Exits 1 when Editroom isn't reachable or the tool reports an error.
set -eu
[ $# -ge 1 ] || { echo "usage: call.sh <tool> ['{json args}'] | call.sh tools" >&2; exit 2; }
exec /usr/bin/python3 - "$@" <<'PY'
import base64, json, os, sys, tempfile, urllib.request, urllib.error
url = "http://127.0.0.1:%s/mcp" % os.environ.get("EDITROOM_PORT", "47920")
tool, args = sys.argv[1], json.loads(sys.argv[2]) if len(sys.argv) > 2 else {}
def post(body, sid=None):
    h = {"Content-Type": "application/json"}
    if sid: h["Mcp-Session-Id"] = sid
    req = urllib.request.Request(url, json.dumps(body).encode(), h)
    try:
        with urllib.request.urlopen(req, timeout=300) as r: return json.load(r), r.headers.get("Mcp-Session-Id")
    except urllib.error.HTTPError as e:
        if e.code == 403: sys.exit("Editroom refused the call. Turn on Settings > Magic > Let AI apps edit in Editroom.")
        sys.exit("Editroom answered HTTP %d: %s" % (e.code, e.read().decode(errors="replace")[:200]))
    except (urllib.error.URLError, OSError):
        sys.exit("Editroom isn't open (nothing at %s). Open it, or set EDITROOM_PORT." % url)
_, sid = post({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2025-06-18", "capabilities": {}, "clientInfo": {"name": "call.sh", "version": "1"}}})
if tool == "tools":
    r, _ = post({"jsonrpc": "2.0", "id": 2, "method": "tools/list"}, sid)
    for t in r["result"]["tools"]: print(t["name"], " ".join(t.get("inputSchema", {}).get("properties", {})))
    sys.exit(0)
r, _ = post({"jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": {"name": tool, "arguments": args}}, sid)
if "error" in r: sys.exit("Editroom: " + r["error"].get("message", "error"))
res = r["result"]
for c in res.get("content", []):
    if c.get("type") == "text": print(c["text"])
    elif c.get("type") == "image":
        ext = c.get("mimeType", "image/jpeg").split("/")[-1]
        fd, path = tempfile.mkstemp(prefix="editroom-", suffix="." + ext)
        os.write(fd, base64.b64decode(c["data"])); os.close(fd)
        print("picture:", path)
sys.exit(1 if res.get("isError") else 0)
PY

