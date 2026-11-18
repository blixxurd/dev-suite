#!/bin/sh
# Starts or continues one trial run: a headless Claude Code session in a folder of its own,
# outside this repo. This file is the one home for how such a session is launched.
#
#   sh trials/run.sh [-b <brief>] [-p] [-r <session id>] <run> <prompt file>
#
#   -b <brief>       start a new run: make its folder and put the brief in it as brief.md
#   -p               load the plugin from this repo (a baseline goes without)
#   -r <session id>  continue that session instead of starting a new one
#
# The run's folder is $TRIALS_HOME/<run>. What each call returns is kept beside it, in
# $TRIALS_HOME/<run>.out/ (N.json, N.err, N.prompt and two lines in log.txt), where the
# project being built never sees it. A new run also records there, in before.txt, what the
# machine looked like before it began. When the run has ended, trials/after.sh reports what
# it did beyond its folder.
#
# What Go, npm and pip download or build for a run goes beside it as well, in
# $TRIALS_HOME/<run>.cache/, and not in the user's home, and so do the links uv makes to a
# Python it installs. The settings that do it are written
# to <run>.out/env.sh, for running the finished project's own commands the same way.
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
TRIALS_HOME=${TRIALS_HOME:-$HOME/Projects/dev-suite-trials}

# Added to every session's system prompt. A run has permission prompts off and the reach of
# the session that started it, and what the owner approved stays inside the run's folder.
# It names no test and no audience, so a run behaves as it would for anyone.
FENCE='Keep to this folder and this machine: install nothing system-wide, and do not add a git remote, push, publish or deploy anything. Permission prompts are off for this session, so nothing will stop you if you do.'

usage() {
  echo 'usage: sh trials/run.sh [-b <brief>] [-p] [-r <session id>] <run> <prompt file>' >&2
  exit 2
}
refuse() {
  echo "run.sh: $1" >&2
  exit 2
}

brief='' plugin=no resume=''
while getopts 'b:pr:' option; do
  case $option in
    b) brief=$OPTARG ;;
    p) plugin=yes ;;
    r) resume=$OPTARG ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))
[ $# -eq 2 ] || usage
run=$1 prompt_file=$2

case $run in
  '' | *[!a-z0-9-]*) refuse "a run is named in lowercase letters, digits and dashes, not '$run'" ;;
esac
[ -f "$prompt_file" ] || refuse "no prompt file at $prompt_file"
prompt=$(cat "$prompt_file")
dir=$TRIALS_HOME/$run
out=$TRIALS_HOME/$run.out
cache=$TRIALS_HOME/$run.cache

if [ -n "$brief" ]; then
  [ -f "$brief" ] || refuse "no brief at $brief"
  [ -z "$resume" ] || refuse '-b starts a new run, which has no session to continue'
  if [ -e "$dir" ] || [ -e "$out" ]; then refuse "a new run needs a new folder, and $dir is taken"; fi
  mkdir -p "$dir" "$out"
  cp "$brief" "$dir/brief.md"
  sh "$root/trials/after.sh" -s > "$out/before.txt"
else
  [ -d "$dir" ] || refuse "no run at $dir; start one with -b <brief>"
  mkdir -p "$out"
fi

# The session id is chosen here, so a run that is stopped before it answers can still be
# continued, and its transcript found.
if [ -n "$resume" ]; then
  session=$resume
  set -- --resume "$session"
else
  session=$(uuidgen | tr 'A-Z' 'a-z')
  set -- --session-id "$session"
fi
[ "$plugin" = no ] || set -- "$@" --plugin-dir "$root/plugin"

call=$(($(find "$out" -name '*.prompt' | wc -l) + 1))
cp "$prompt_file" "$out/$call.prompt"
now() { date -u +%Y-%m-%dT%H:%M:%SZ; }
printf '%s  call %s  start  session %s  plugin %s  prompt %s  cli %s\n' \
  "$(now)" "$call" "$session" "$plugin" "$prompt_file" "$(claude --version | head -n 1)" >> "$out/log.txt"
echo "run.sh: $run, call $call, session $session"

# Left alone, Go would make ~/go, all three would fill folders in the user's home, and uv
# would put a python3.X link in ~/.local/bin, ahead of the machine's own Python on the PATH.
cat > "$out/env.sh" <<ENV
export GOPATH='$cache/go' GOCACHE='$cache/go-build'
export npm_config_cache='$cache/npm' PIP_CACHE_DIR='$cache/pip'
export UV_PYTHON_BIN_DIR='$cache/uv-bin'
ENV
. "$out/env.sh"

cd "$dir"
status=0
# CLAUDE_EFFORT is unset because the session these runs are started from sets its own effort
# and a child would inherit it; without it the run is on the user's own settings. The other
# marks that session leaves in the environment (CLAUDE_CODE_CHILD_SESSION and the like) stay:
# they tell the CLI an agent started this run, which keeps it out of the user's prompt history.
# Without < /dev/null the CLI waits three seconds for piped input.
env -u CLAUDE_EFFORT claude -p "$prompt" "$@" \
  --append-system-prompt "$FENCE" \
  --output-format json --permission-mode bypassPermissions \
  < /dev/null > "$out/$call.json" 2> "$out/$call.err" || status=$?

printf '%s  call %s  exit %s\n' "$(now)" "$call" "$status" >> "$out/log.txt"
echo "run.sh: exit $status, output in $out/$call.json"
exit "$status"
