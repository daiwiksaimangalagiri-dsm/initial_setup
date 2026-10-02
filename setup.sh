#!/usr/bin/env bash
# The one command: install everything on this machine, set up the repo, verify both.
#   initial-setup [dir] [--update-skills]     (dir defaults to the current directory)
set -euo pipefail
SELF=$(readlink "$0" 2>/dev/null || echo "$0")
REPO=$(cd "$(dirname "$SELF")" && pwd)
DIR=$PWD; FLAGS=()
for a in "$@"; do case $a in --*) FLAGS+=("$a");; *) DIR=$a;; esac; done

"$REPO/scripts/install.sh" ${FLAGS[@]+"${FLAGS[@]}"}
"$REPO/scripts/project-setup.sh" "$DIR"
"$REPO/scripts/verify.sh" --smoke "$DIR"
