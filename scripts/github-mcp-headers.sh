#!/usr/bin/env bash
# Prints the auth header for the GitHub MCP server. The token is read at connect time and never stored in Claude's config.
# Order: gh's login, then the GitHub login saved in the macOS keychain.
export PATH="$HOME/.local/bin:$PATH"
TOKEN=$(gh auth token 2>/dev/null)
[ -n "$TOKEN" ] || TOKEN=$(printf "protocol=https\nhost=github.com\n\n" | git credential-osxkeychain get 2>/dev/null | sed -n 's/^password=//p')
[ -n "$TOKEN" ] || { echo "No GitHub token: run gh auth login --git-protocol https --web" >&2; exit 1; }
printf '{"Authorization": "Bearer %s"}\n' "$TOKEN"
