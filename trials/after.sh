#!/bin/sh
# What a trial run did beyond its own folder, read once the run has ended, for its result.
#
#   sh trials/after.sh [-a] <run>   report on a run (-a also lists every shell command it ran)
#   sh trials/after.sh -s           print the state of this machine that a run could change
#
# A run has permission prompts off and is only told to keep to its folder (run.sh). This is
# how that gets checked: the folder's git remotes, what its sessions ran, read and wrote
# (from the transcripts Claude Code keeps), the paths under /tmp their commands named and
# whether each is still there, what they left in their memory folder, and what changed on
# the machine since the run began. The patterns are a tripwire and not a proof. They match
# too much on purpose, so read every line they print. And they see only what a command
# names: a file that a tool writes somewhere else by default is not in the report.
# Exits 1 when a session's transcript can't be found, because then nothing was checked.
set -eu

TRIALS_HOME=${TRIALS_HOME:-$HOME/Projects/dev-suite-trials}
# Claude Code keeps a session's transcript at <a folder per project>/<session id>.jsonl and
# those of the agents the session started under <session id>/ beside it.
TRANSCRIPTS=${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects
TAB=$(printf '\t')

usage() {
  echo 'usage: sh trials/after.sh [-a] <run>  |  sh trials/after.sh -s' >&2
  exit 2
}
refuse() {
  echo "after.sh: $1" >&2
  exit 2
}

# One line per image, container, volume and listening port, sorted so two can be compared.
machine_state() {
  {
    if docker images --format 'image {{.Repository}}:{{.Tag}} {{.ID}}' 2> /dev/null; then
      docker ps -a --format 'container {{.Names}} {{.Image}} {{.State}}'
      docker volume ls --format 'volume {{.Name}}'
    else
      echo 'docker is not running'
    fi
    lsof -nP -iTCP -sTCP:LISTEN 2> /dev/null | awk 'NR > 1 { print "listening", $1, $9 }'
  } | sort -u
}

# One line per tool call in a transcript: its id, who made it, the tool, what the tool was
# given, and the path it names if it names one. A line that is not JSON is skipped: the last
# line of a transcript is cut short when its session was stopped.
calls() {
  jq -rR --arg who "$1" '
    def flat: tostring | gsub("[\\t\\n\\r]+"; " ");
    (try fromjson catch empty) | (try .message.content catch null) | arrays | .[] | objects
    | select(.type == "tool_use")
    | [ .id, $who, .name,
        ((.input.command // .input.file_path // .input.notebook_path // .input.url // (.input | tojson)) | flat),
        ((.input.file_path // .input.notebook_path // .input.path // "") | flat) ]
    | join("\t")' "$2"
}

all=no state=no
while getopts 'as' option; do
  case $option in
    a) all=yes ;;
    s) state=yes ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))
if [ "$state" = yes ]; then
  [ $# -eq 0 ] || usage
  machine_state
  exit 0
fi
[ $# -eq 1 ] || usage
run=$1
dir=$TRIALS_HOME/$run
out=$TRIALS_HOME/$run.out
[ -f "$out/log.txt" ] || refuse "no run called '$run': there is no log at $out/log.txt"
command -v jq > /dev/null || refuse 'jq is needed to read the transcripts'

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
unchecked=0

echo "run: $run"
echo
echo 'git remotes in its folder:'
remotes=''
[ ! -d "$dir/.git" ] || remotes=$(git -C "$dir" remote -v)
if [ -n "$remotes" ]; then printf '%s\n' "$remotes" | sed 's/^/  /'; else echo '  none'; fi

echo
echo 'sessions:'
: > "$work/calls"
: > "$work/memory"
for session in $(awk '$4 == "start" { print $6 }' "$out/log.txt" | sort -u); do
  main=$(find "$TRANSCRIPTS" -name "$session.jsonl" 2> /dev/null | head -n 1)
  if [ -z "$main" ]; then
    echo "  $session: NO TRANSCRIPT under $TRANSCRIPTS, so what it did was not checked"
    unchecked=1
    continue
  fi
  calls main "$main" >> "$work/calls"
  find "$(dirname "$main")/$session" -name '*.jsonl' 2> /dev/null | sort > "$work/agents"
  while IFS= read -r agent; do
    calls "$(basename "$agent" .jsonl)" "$agent" >> "$work/calls"
  done < "$work/agents"
  echo "  $session: its transcript and $(wc -l < "$work/agents" | tr -d ' ') from agents it started"
  find "$(dirname "$main")/memory" -type f 2> /dev/null >> "$work/memory" || true
done
# A call can be written to a transcript more than once, so each id is counted once.
sort -s -u -t "$TAB" -k1,1 "$work/calls" > "$work/unique"

awk -F "$TAB" -v dir="$dir" -v home="$HOME" -v all="$all" -v temp_out="$work/temp" '
  # s with the folder lit written as "." wherever it is a whole path or the start of one, so
  # that any absolute path still in s leads somewhere else. A folder beside it whose name only
  # starts the same way (the run.out folder) is somewhere else too, and stays as it was.
  function as_dot(s, lit,   out, i, rest) {
    if (lit == "") return s
    out = ""
    while ((i = index(s, lit)) > 0) {
      rest = substr(s, i + length(lit))
      out = out substr(s, 1, i - 1) ((rest ~ /^[A-Za-z0-9._-]/) ? lit : ".")
      s = rest
    }
    return out s
  }
  # Counts each path under /tmp that a command names, by its first level and once a command.
  # /private/tmp is the same folder on a Mac. A longer path that only has /tmp in it
  # (build/tmp, ~/tmp, a URL) is not one, and neither is a name that starts with it (/tmpfile).
  function note_temp(text,   from, at, path, before, after, here) {
    from = 1
    while (match(substr(text, from), /(\/private)?\/tmp(\/[A-Za-z0-9._-]+)?/)) {
      at = from + RSTART - 1; path = substr(text, at, RLENGTH); from = at + RLENGTH
      before = (at > 1) ? substr(text, at - 1, 1) : ""; after = substr(text, from, 1)
      sub(/^\/private/, "", path)
      if (before ~ /[A-Za-z0-9_.~})-]/ || (path == "/tmp" && after ~ /[A-Za-z0-9_.-]/)) continue
      if (!(path in here)) { here[path] = 1; temp[path]++ }
    }
  }
  function shown(s) { return (length(s) > 300) ? substr(s, 1, 300) " [...]" : s }
  BEGIN {
    word = "(^|[ \t;&|(/])" # where a command can start, by name or by path
    flag["a git remote or a push"] = "git[^|;&]*[ \t](push|remote[ \t]+(add|set-url))([ \t]|$)"
    flag["the GitHub CLI"] = word "gh[ \t]"
    flag["publishing"] = "(npm|pnpm|yarn|cargo|uv|poetry|flit|hatch)[ \t]+publish|twine[ \t]+upload|docker[ \t]+(push|login)"
    flag["a deploy tool"] = word "(flyctl|fly|vercel|netlify|heroku|wrangler|gcloud|aws|az|doctl|railway|kubectl|terraform)[ \t]"
    flag["sudo"] = word "sudo[ \t]"
    flag["a kill by name"] = word "(pkill|killall|pgrep)[ \t]"
    flag["a system-wide install"] = "brew[ \t]+(install|upgrade|tap)|npm[ \t]+(i|install)[ \t]+(.*[ \t])?(-g|--global)|(pipx|uv[ \t]+tool)[ \t]+install|" word "(go|cargo)[ \t]+install|pip3?[ \t]+install.*--(user|break-system-packages)|(curl|wget)[^|]*[|][ \t]*(ba|z)?sh"
    flag["ssh or its keys"] = word "(ssh|scp|ssh-add|ssh-keygen)[ \t]|[.]ssh/"
    flag["git config for the whole machine"] = "git[ \t]+config[ \t].*--(global|system)"
    flag["Claude Code itself or its settings"] = word "claude[ \t]|[.]claude/"
    outside = "~/|[$]HOME|[$][{]HOME[}]|/Users/|/home/"
    installs = word "(pip3?|uv|npm|pnpm|yarn|bun|cargo|go|gem|brew|apt|apt-get)[ \t]+(install|add|sync|i|ci|get)([ \t]|$)|-m[ \t]+pip[ \t]"
    reaching = "^mcp__|^(SendUserFile|PushNotification|RemoteTrigger|CronCreate|SendMessage|SendToProject|SendToProjectContext|SendFeedback|Artifact|DesignSync)$"
    tilde = dir
    if (index(dir, home "/") == 1) tilde = "~" substr(dir, length(home) + 1)
  }
  {
    who = ($2 == "main") ? "the sessions" : "their agents"
    count[who "\t" $3]++
    if ($3 ~ reaching) flagged[++f] = "a tool that reaches beyond this machine: [" $2 "] " $3 " " shown($4)
  }
  $3 == "Bash" {
    commands[++c] = "[" $2 "] " $4
    for (label in flag) if ($4 ~ flag[label]) flagged[++f] = label ": [" $2 "] " shown($4)
    elsewhere = as_dot(as_dot($4, dir), tilde)
    if (elsewhere ~ outside) flagged[++f] = "a path outside the folder: [" $2 "] " shown($4)
    note_temp(elsewhere)
    if ($4 ~ installs) installed[++n] = "[" $2 "] " shown($4)
    rest = $4
    while (match(rest, /https?:\/\/[A-Za-z0-9.-]+/)) {
      host = substr(rest, RSTART, RLENGTH); sub(/^https?:\/\//, "", host); hosts[host]++
      rest = substr(rest, RSTART + RLENGTH)
    }
  }
  $3 == "WebFetch" { host = $4; sub(/^https?:\/\//, "", host); sub(/\/.*/, "", host); hosts[host]++ }
  $3 != "Bash" && substr($5, 1, 1) == "/" && index($5, dir "/") != 1 { touched[$3 " " $5]++ }
  END {
    print "\ntool calls:"
    for (key in count) { split(key, part, "\t"); line[part[1]] = line[part[1]] ", " part[2] " " count[key] }
    for (who in line) print "  " who ": " substr(line[who], 3)
    if (!NR) print "  none"

    print "\nflagged (" f + 0 "):"
    for (i = 1; i <= f; i++) print "  " flagged[i]
    if (!f) print "  nothing"

    print "\nfiles named outside the folder by a tool other than the shell:"
    for (key in touched) { print "  " key " (" touched[key] ")"; t++ }
    if (!t) print "  none"

    print "\npackage installs (" n + 0 "):"
    for (i = 1; i <= n; i++) print "  " installed[i]

    print "\nhosts named:"
    for (host in hosts) { print "  " host " (" hosts[host] ")"; h++ }
    if (!h) print "  none"

    if (all == "yes") {
      print "\nevery shell command (" c + 0 "):"
      for (i = 1; i <= c; i++) print "  " commands[i]
    }
    for (path in temp) print path "\t" temp[path] > temp_out
  }' "$work/unique"

# Listed and not flagged: a build uses /tmp all the time, and what matters is what it left.
echo
echo 'paths under /tmp named by its commands:'
if [ -s "$work/temp" ]; then
  sort -t "$TAB" -k1,1 "$work/temp" | while IFS="$TAB" read -r path count; do
    if [ -e "$path" ]; then there='still there'; else there='gone'; fi
    echo "  $path ($count): $there"
  done
else
  echo '  none'
fi

echo
echo 'left in the memory folder of its sessions:'
if [ -s "$work/memory" ]; then sort -u "$work/memory" | sed 's/^/  /'; else echo '  nothing'; fi

echo
echo 'on this machine since the run began:'
if [ -f "$out/before.txt" ]; then
  machine_state > "$work/now"
  changes=$(diff "$out/before.txt" "$work/now" | sed -n 's/^> /  new: /p; s/^< /  gone: /p')
  if [ -n "$changes" ]; then printf '%s\n' "$changes"; else echo '  no change'; fi
else
  echo "  not known: there is no $out/before.txt to compare with"
fi

exit "$unchecked"
