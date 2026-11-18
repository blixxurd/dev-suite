#!/bin/sh
# Proves trials/run.sh with a stand-in for the CLI, so no session is started:
# what a run's folder holds, how the CLI is called, and what the runner refuses.
# Docker and lsof are stand-ins too, so the result doesn't depend on what this machine runs.
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
runner=$root/trials/run.sh
brief=$root/trials/service-brief.md

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cases=0
fail() {
  echo "test-run: FAIL: $1" >&2
  exit 1
}
pass() { cases=$((cases + 1)); }

# The stand-in records where it ran, what it was given and what reached its stdin.
mkdir "$tmp/bin" "$tmp/seen"
cat > "$tmp/bin/claude" <<'STANDIN'
#!/bin/sh
if [ "${1:-}" = --version ]; then echo '0.0.0 (stand-in)'; exit 0; fi
pwd -P > "$SEEN/cwd"
printenv CLAUDE_EFFORT > "$SEEN/effort"
printf '%s\n' "${GOPATH:-}" "${GOCACHE:-}" "${npm_config_cache:-}" "${PIP_CACHE_DIR:-}" "${UV_PYTHON_BIN_DIR:-}" > "$SEEN/caches"
cat > "$SEEN/stdin"
for arg in "$@"; do printf '%s\n' "$arg"; done > "$SEEN/args"
echo '{"result":"stand-in"}'
echo 'stand-in warning' >&2
exit "${STANDIN_EXIT:-0}"
STANDIN
cat > "$tmp/bin/docker" <<'STANDIN'
#!/bin/sh
[ "$1" != images ] || echo "image ${STANDIN_IMAGE:-base:1} aaaa"
STANDIN
cat > "$tmp/bin/lsof" <<'STANDIN'
#!/bin/sh
echo 'COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME'
echo 'steam 1 me 4u IPv4 0x1 0t0 TCP *:27036 (LISTEN)'
STANDIN
chmod +x "$tmp/bin/claude" "$tmp/bin/docker" "$tmp/bin/lsof"
export PATH="$tmp/bin:$PATH" SEEN="$tmp/seen" TRIALS_HOME="$tmp/home" CLAUDE_EFFORT=max
printf 'Build it.\n' > "$tmp/prompt.md"
printf 'Approved.\n' > "$tmp/approve.md"

# The argument that follows a flag, as the stand-in saw it.
after() { awk -v flag="$1" '$0 == flag { getline; print; exit }' "$SEEN/args"; }
has() { grep -q -x -e "$1" "$SEEN/args"; }
run() { echo 'typed by nobody' | sh "$runner" "$@" > "$tmp/stdout" 2> "$tmp/stderr"; }

run -b "$brief" first "$tmp/prompt.md" || fail 'a new run did not go through'
pass
[ "$(ls -A "$TRIALS_HOME/first")" = brief.md ] && cmp -s "$brief" "$TRIALS_HOME/first/brief.md" ||
  fail 'a new folder should hold the brief as brief.md and nothing else'
pass
[ "$(cat "$SEEN/cwd")" = "$(cd "$TRIALS_HOME/first" && pwd -P)" ] || fail 'the session was not started in the run folder'
pass
[ "$(after -p)" = 'Build it.' ] || fail 'the prompt was not passed'
pass
session=$(after --session-id)
printf '%s\n' "$session" | grep -Eq '^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$' || fail "not a lowercase session id: $session"
pass
if has --plugin-dir || has --resume; then fail 'a new run without -p loaded the plugin or continued a session'; fi
pass
after --append-system-prompt | grep -q 'do not add a git remote, push, publish or deploy' || fail 'the fence was not passed'
pass
[ "$(after --output-format)" = json ] && [ "$(after --permission-mode)" = bypassPermissions ] ||
  fail 'the output format or the permission mode is not as recorded'
pass
[ ! -s "$SEEN/effort" ] || fail "the caller's CLAUDE_EFFORT reached the session"
pass
[ ! -s "$SEEN/stdin" ] || fail 'the session was left reading the caller stdin'
pass
out=$TRIALS_HOME/first.out
cache=$TRIALS_HOME/first.cache
[ "$(cat "$SEEN/caches")" = "$(printf '%s\n' "$cache/go" "$cache/go-build" "$cache/npm" "$cache/pip" "$cache/uv-bin")" ] ||
  fail 'Go, npm, pip and uv were not pointed at a folder beside the run'
pass
[ "$(. "$out/env.sh" && printf '%s\n' "$GOPATH" "$GOCACHE" "$npm_config_cache" "$PIP_CACHE_DIR" "$UV_PYTHON_BIN_DIR")" = "$(cat "$SEEN/caches")" ] ||
  fail 'env.sh does not hold the settings the session was given'
pass
grep -q stand-in "$out/1.json" && grep -q warning "$out/1.err" && cmp -s "$tmp/prompt.md" "$out/1.prompt" ||
  fail 'the output, the errors or the prompt were not kept beside the run'
pass
grep -q "call 1  start  session $session  plugin no" "$out/log.txt" && grep -q 'call 1  exit 0' "$out/log.txt" ||
  fail 'the log does not record the call and how it ended'
pass
[ "$(cat "$out/before.txt")" = "$(printf '%s\n' 'image base:1 aaaa' 'listening steam *:27036')" ] ||
  fail 'a new run did not record what the machine looked like before it began'
pass

STANDIN_IMAGE=built:2 run -p -r "$session" first "$tmp/approve.md" || fail 'continuing a run did not go through'
pass
grep -q 'base:1' "$out/before.txt" || fail 'continuing a run replaced the record of the machine before it began'
pass
[ "$(after --resume)" = "$session" ] || fail 'the session was not continued'
pass
if has --session-id; then fail 'a continued run was given a new session id'; fi
pass
[ "$(after --plugin-dir)" = "$root/plugin" ] || fail '-p did not load the plugin from this repo'
pass
[ -s "$out/2.json" ] && grep -q 'call 2  start' "$out/log.txt" || fail 'the second call was not numbered 2'
pass

status=0
STANDIN_EXIT=3 run first "$tmp/prompt.md" || status=$?
[ "$status" = 3 ] && grep -q 'call 3  exit 3' "$out/log.txt" || fail "a failing session's exit status was not passed on and logged"
pass

# What it refuses, each before the CLI is called.
refuses() {
  what=$1
  shift
  rm -f "$SEEN/args"
  status=0
  run "$@" || status=$?
  [ "$status" = 2 ] && [ ! -e "$SEEN/args" ] || fail "did not refuse $what"
  pass
}
refuses 'a new run in a folder that is taken' -b "$brief" first "$tmp/prompt.md"
refuses 'a run that was never started' second "$tmp/prompt.md"
refuses 'a missing prompt file' first "$tmp/no-such.md"
refuses 'a brief together with a session to continue' -b "$brief" -r "$session" third "$tmp/prompt.md"
refuses 'a run name that leaves the trials folder' -b "$brief" ../outside "$tmp/prompt.md"
refuses 'a call with no prompt file' first
[ ! -e "$tmp/outside" ] && [ ! -e "$TRIALS_HOME/third" ] || fail 'a refused run left a folder behind'
pass

echo "test-run: ok ($cases cases)"
