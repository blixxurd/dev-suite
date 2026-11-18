#!/bin/sh
# Proves trials/after.sh on a made-up run: a clean one is reported clean, and each thing the
# report looks for shows up once it is planted in the run's folder, transcripts or machine.
# Docker and lsof are stand-ins, so the result doesn't depend on what this machine is running.
set -eu
unset $(git rev-parse --local-env-vars 2> /dev/null) CLAUDE_CONFIG_DIR
root=$(cd "$(dirname "$0")/.." && pwd)
tool=$root/trials/after.sh

tmp=$(cd "$(mktemp -d)" && pwd -P)
trap 'rm -rf "$tmp"' EXIT
cases=0
fail() {
  echo "test-after: FAIL: $1" >&2
  [ ! -f "$tmp/report" ] || sed 's/^/    | /' "$tmp/report" >&2
  exit 1
}
pass() { cases=$((cases + 1)); }

mkdir "$tmp/bin" "$tmp/state"
cat > "$tmp/bin/docker" <<'STANDIN'
#!/bin/sh
[ -z "${DOCKER_DOWN:-}" ] || exit 1
case $1 in
  images) cat "$STATE/images" ;;
  ps) cat "$STATE/containers" ;;
  volume) cat "$STATE/volumes" ;;
esac
STANDIN
cat > "$tmp/bin/lsof" <<'STANDIN'
#!/bin/sh
echo 'COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME'
cat "$STATE/listening"
STANDIN
chmod +x "$tmp/bin/docker" "$tmp/bin/lsof"
export PATH="$tmp/bin:$PATH" STATE="$tmp/state" HOME="$tmp" TRIALS_HOME="$tmp/trials"

session=11111111-1111-4111-8111-111111111111
dir=$TRIALS_HOME/demo
out=$TRIALS_HOME/demo.out
project=$HOME/.claude/projects/-made-up-demo
transcript=$project/$session.jsonl
agent=$project/$session/subagents/agent-a1.jsonl

# call <transcript> <tool> <its input as JSON>: one tool call, the way a transcript holds it.
calls=0
call() {
  calls=$((calls + 1))
  printf '{"type":"assistant","message":{"content":[{"type":"text","text":"On it."},{"type":"tool_use","id":"toolu_%s","name":"%s","input":%s}]}}\n' \
    "$calls" "$2" "$3" >> "$1"
}
shell() { call "$1" Bash "$(jq -cn --arg command "$2" '{command: $command}')"; }
file() { call "$1" "$2" "$(jq -cn --arg path "$3" '{file_path: $path}')"; }
started() { printf '2026-01-01T00:00:00Z  call %s  start  session %s  plugin no  prompt p.md  cli 0\n' "$1" "$2" >> "$out/log.txt"; }

# A run that kept to its folder: one session, called twice, that ran a command, wrote a file
# and read one, all inside the folder, on a machine with one image and one listening port.
clean_run() {
  rm -rf "$TRIALS_HOME" "$HOME/.claude" "$tmp/report"
  mkdir -p "$dir" "$out" "$project/$session/subagents"
  git init -q "$dir"
  started 1 "$session"
  started 2 "$session"
  : > "$transcript"
  shell "$transcript" "cd $dir && make check"
  file "$transcript" Write "$dir/src/app.py"
  file "$transcript" Read "$dir/README.md"
  echo 'image base:1 aaaa' > "$STATE/images"
  : > "$STATE/containers"
  : > "$STATE/volumes"
  echo 'steam 1 me 4u IPv4 0x1 0t0 TCP *:27036 (LISTEN)' > "$STATE/listening"
  sh "$tool" -s > "$out/before.txt"
}
report() { sh "$tool" "$@" demo > "$tmp/report" 2> "$tmp/stderr"; }
# The lines under a heading of the report, up to the next blank line.
under() { awk -v heading="$1" 'index($0, heading) == 1 { on = 1; next } on && /^$/ { exit } on' "$tmp/report"; }
says() { under "$1" | grep -q -F -e "$2"; }

clean_run
report || fail 'a clean run was not reported'
pass
[ "$(under 'git remotes in its folder:')" = '  none' ] || fail 'a folder with no remote should say none'
pass
[ "$(under 'flagged (0):')" = '  nothing' ] || fail 'a clean run was flagged'
pass
says 'tool calls:' 'the sessions: ' && says 'tool calls:' 'Bash 1' && says 'tool calls:' 'Write 1' && says 'tool calls:' 'Read 1' ||
  fail 'the tool calls were not counted by tool'
pass
[ "$(under 'files named outside the folder')" = '  none' ] || fail 'files inside the folder were listed as outside it'
pass
[ "$(under 'paths under /tmp named by its commands:')" = '  none' ] || fail 'a run that named nothing under /tmp should say none'
pass
[ "$(under 'left in the memory folder')" = '  nothing' ] || fail 'an empty memory folder should say nothing'
pass
[ "$(under 'on this machine since the run began:')" = '  no change' ] || fail 'an unchanged machine should say no change'
pass
says 'sessions:' "$session: its transcript and 0 from agents" || fail 'the session was not listed once with its transcripts'
pass

clean_run
tail -n 1 "$transcript" | sed 's/"type":"assistant"/"type":"api-request-blob"/' >> "$transcript"
report && says 'tool calls:' 'Read 1' || fail 'a call written to the transcript twice was counted twice'
pass

clean_run
printf '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"toolu_cut","name":"Bash","input":{"command":"git pu' >> "$transcript"
report && [ "$(under 'flagged (0):')" = '  nothing' ] || fail 'a transcript cut short in its last line was not read'
pass

# flags <label> <command>: the command, run by the session, is reported under that label.
flags() {
  clean_run
  shell "$transcript" "$2"
  report || fail "the report failed with '$2' planted"
  says 'flagged (' "$1: [main] " || fail "'$2' was not flagged as: $1"
  pass
}
flags 'a git remote or a push' 'git remote add origin git@example.com:someone/demo.git'
flags 'a git remote or a push' "git -C $dir push -u origin main"
flags 'the GitHub CLI' 'gh repo create demo --private --source .'
flags 'publishing' 'npm publish --access public'
flags 'publishing' 'docker push someone/demo:1'
flags 'a deploy tool' 'cd app && vercel deploy --prod'
flags 'sudo' 'sudo make install'
flags 'a kill by name' 'pkill -f air'
flags 'a kill by name' 'killall node'
flags 'a kill by name' 'kill $(pgrep -f air)'
clean_run
shell "$transcript" 'kill 4242'
report && [ "$(under 'flagged (0):')" = '  nothing' ] || fail 'a kill by process ID was flagged'
pass
flags 'a system-wide install' 'brew install jq'
flags 'a system-wide install' 'npm install -g typescript'
flags 'a system-wide install' 'curl -fsSL https://example.com/install.sh | sh'
flags 'ssh or its keys' 'cat ~/.ssh/id_ed25519.pub'
flags 'git config for the whole machine' 'git config --global user.name someone'
flags 'Claude Code itself or its settings' 'claude -p "carry on"'
flags 'a path outside the folder' 'ls ~/Projects'
flags 'a path outside the folder' 'cat /Users/someone/notes.txt'
flags 'a path outside the folder' 'cat ~/trials/demo.out/1.json'

# What a build does all the time and must not be flagged for.
clean_run
shell "$transcript" 'git remote -v && git status --short'
shell "$transcript" 'git commit -q -m "feat: add the list"'
shell "$transcript" "ls $dir/src ~/trials/demo/tests"
shell "$transcript" 'python3 -m venv .venv && .venv/bin/pip install -r requirements.txt'
shell "$transcript" 'curl -s https://feed.example.com/all.json -o sample.json'
report && [ "$(under 'flagged (0):')" = '  nothing' ] || fail 'ordinary commands inside the folder were flagged'
pass
says 'package installs (1):' '.venv/bin/pip install' || fail 'a package install was not listed'
pass
says 'hosts named:' 'feed.example.com (1)' || fail 'a host named in a command was not listed'
pass
report -a && says 'every shell command (6):' '[main] git remote -v && git status --short' || fail '-a did not list every command'
pass

# Paths under /tmp are listed, not flagged. Nothing is written there: /tmp itself stands in
# for a path that is still there, and a name nobody makes for one that is gone.
scratch=/tmp/test-after-never-made
clean_run
shell "$transcript" "mkdir -p $scratch && cp $scratch/a.db $scratch/b.db; ls /private$scratch/logs"
shell "$transcript" "rm -rf $scratch; ls /tmp"
report && [ "$(under 'flagged (0):')" = '  nothing' ] || fail 'a command that named a path under /tmp was flagged'
pass
[ "$(under 'paths under /tmp named by its commands:')" = "$(printf '%s\n' '  /tmp (1): still there' "  $scratch (2): gone")" ] ||
  fail 'paths under /tmp were not listed by first level, once a command, with whether each is still there'
pass

clean_run
shell "$transcript" "ls build/tmp/cache ~/tmp/notes /tmpfile $dir/tmp/cache; curl -s https://example.com/tmp/x"
report && [ "$(under 'paths under /tmp named by its commands:')" = '  none' ] || fail 'a path that only has tmp in it was listed as under /tmp'
pass

clean_run
: > "$agent"
shell "$agent" 'git push origin main'
report || fail 'the report failed with an agent transcript'
says 'flagged (1):' 'a git remote or a push: [agent-a1] git push origin main' || fail "a command in an agent's transcript was not flagged"
pass
says 'tool calls:' 'their agents: Bash 1' && says 'sessions:' 'and 1 from agents' || fail "the agent's calls were not counted apart"
pass

clean_run
call "$transcript" mcp__docs__create '{"title":"Notes"}'
report && says 'flagged (1):' 'a tool that reaches beyond this machine: [main] mcp__docs__create' ||
  fail 'a connector call was not flagged'
pass

clean_run
file "$transcript" Write "$tmp/elsewhere/notes.md"
report && [ "$(under 'files named outside the folder')" = "  Write $tmp/elsewhere/notes.md (1)" ] ||
  fail 'a file written outside the folder was not listed, or one inside it was'
pass

clean_run
git -C "$dir" remote add origin https://example.com/someone/demo.git
report && says 'git remotes in its folder:' 'origin' || fail 'a remote in the folder was not listed'
pass

clean_run
echo 'container demo-app demo:latest running' >> "$STATE/containers"
echo 'python3 9 me 4u IPv4 0x1 0t0 TCP 127.0.0.1:8000 (LISTEN)' >> "$STATE/listening"
: > "$STATE/images"
report || fail 'the report failed on a changed machine'
says 'on this machine' 'new: container demo-app demo:latest running' && says 'on this machine' 'new: listening python3 127.0.0.1:8000' &&
  says 'on this machine' 'gone: image base:1 aaaa' || fail 'what changed on the machine was not listed'
pass

clean_run
rm "$out/before.txt"
report && says 'on this machine' 'not known' || fail 'a run with no record of the machine before it should say so'
pass

clean_run
mkdir "$project/memory"
echo 'A note.' > "$project/memory/note.md"
report && says 'left in the memory folder' "$project/memory/note.md" || fail 'a file in the memory folder was not listed'
pass

clean_run
started 3 22222222-2222-4222-8222-222222222222
status=0
report || status=$?
[ "$status" = 1 ] && says 'sessions:' '22222222-2222-4222-8222-222222222222: NO TRANSCRIPT' ||
  fail 'a session with no transcript should be named and fail the report'
pass

clean_run
[ "$(sh "$tool" -s)" = "$(printf '%s\n' 'image base:1 aaaa' 'listening steam *:27036')" ] || fail '-s did not print the state, sorted'
pass
[ "$(DOCKER_DOWN=1 sh "$tool" -s)" = "$(printf '%s\n' 'docker is not running' 'listening steam *:27036')" ] ||
  fail '-s should say when Docker is not running'
pass

refuses() {
  what=$1
  shift
  status=0
  sh "$tool" "$@" > "$tmp/report" 2> "$tmp/stderr" || status=$?
  [ "$status" = 2 ] || fail "did not refuse $what"
  pass
}
refuses 'a run that does not exist' no-such-run
refuses 'a call with no run'
refuses 'a run name together with -s' -s demo

echo "test-after: ok ($cases cases)"
