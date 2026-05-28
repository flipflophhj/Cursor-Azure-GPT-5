#!/usr/bin/env bash
# Start the local Cursor Azure proxy service.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ -x ".venv/bin/python" ]; then
    VENV_PY=".venv/bin/python"
elif [ -x ".venv/Scripts/python.exe" ]; then
    VENV_PY=".venv/Scripts/python.exe"
else
    VENV_PY=""
fi

if [ ! -d ".venv" ]; then
    echo "[cursor-api] Creating virtual environment..."
    uv venv .venv
    if [ -x ".venv/bin/python" ]; then
        VENV_PY=".venv/bin/python"
    elif [ -x ".venv/Scripts/python.exe" ]; then
        VENV_PY=".venv/Scripts/python.exe"
    fi
    uv pip install --python "$VENV_PY" -r requirements/dev.txt -q
fi

if [ -z "$VENV_PY" ]; then
    echo "[cursor-api] Could not find virtualenv interpreter in .venv."
    echo "[cursor-api] Expected one of:"
    echo "  .venv/bin/python"
    echo "  .venv/Scripts/python.exe"
    exit 1
fi

if ! "$VENV_PY" -c "import flask" >/dev/null 2>&1; then
    echo "[cursor-api] Installing dependencies..."
    uv pip install --python "$VENV_PY" -r requirements/dev.txt -q
fi

PORT="${1:-8082}"
SERVICE_KEY="${SERVICE_API_KEY:-}"

if [ -z "${SERVICE_KEY}" ] && [ -f ".env" ]; then
    SERVICE_KEY="$(grep '^SERVICE_API_KEY=' ".env" | cut -d= -f2- || true)"
fi

SERVICE_KEY="${SERVICE_KEY:-change-me}"
if [ "${#SERVICE_KEY}" -le 8 ]; then
    SERVICE_KEY_DISPLAY="..."
else
    SERVICE_KEY_DISPLAY="${SERVICE_KEY:0:4}...${SERVICE_KEY: -4}"
fi

echo "[cursor-api] Starting on http://localhost:$PORT"
echo "[cursor-api] Service API key: ${SERVICE_KEY_DISPLAY}"
echo ""
echo "  Cursor settings:"
echo "    OpenAI API Key    -> ${SERVICE_KEY_DISPLAY}"
echo "    Override Base URL -> <public URL reachable by Cursor servers>"
echo ""
echo "  Local health check:"
echo "    http://localhost:${PORT}/health"
echo ""
echo "  Expose http://localhost:${PORT} through a domain, reverse proxy, or"
echo "  Cloudflare Tunnel, then use that public URL in Cursor."
echo ""
echo "  Supported model ids to add in Cursor:"
echo "    gpt-5"
echo "    gpt-5-mini"
echo "    gpt-5-codex"
echo "    gpt-5.1"
echo "    gpt-5.1-codex"
echo "    gpt-5.1-codex-max"
echo "    gpt-5.1-codex-mini"
echo "    gpt-5.2"
echo "    gpt-5.2-codex"
echo "    gpt-5.3-codex"
echo "    gpt-5.5"
echo "    gpt-5.4"
echo "    gpt-5.4-mini"
echo "    gpt-5.4-nano"
echo ""
echo "  Optional deployment mapping:"
echo '    AZURE_MODEL_DEPLOYMENTS='\''{"gpt-5.4":"my-prod-gpt54","gpt-5.4-mini":"team-mini"}'\'''
echo ""

FLASK_APP=autoapp.py FLASK_ENV=production "$VENV_PY" -m flask run -p "$PORT"
