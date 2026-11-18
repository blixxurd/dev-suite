#!/bin/sh
# usage: sh trials/outcome/chain.sh <plugin|plain|slim|frozen|floor> <first request number>
# Sends the outcome test's requests in order, each in a new session, and after each one runs
# the hidden checks and the project's own tests. Stops at the first call that fails.
# As run, this file and checks.py sat beside the run folders, in outcome-b.checks/, where no
# session looked. In this copy the paths are worked out from where the file is, and the fixed
# folders the checks compare against are in corpus.tar.gz, to be unpacked beside checks.py.
side=$1 first=${2:-1}
T=${TRIALS_HOME:-$HOME/Projects/dev-suite-trials}
C=$(cd "$(dirname "$0")" && pwd)
R=$(cd "$C/../.." && pwd)
run=outcome-b-$side; dir=$T/$run; log=$C/results/$side-chain.log
mkdir -p "$C/results"
flag=''; steps='1 2 3 4'; checkside=$side; prefix=''
[ "$side" = plugin ] && flag=-p && steps='1 2 3 4 ship'
# Any other side (slim, frozen): the plugin as changed since, on a fresh copy, the four requests only
# floor: the plugin-built project, its rules brought up to date, with plain Claude and no plugin
case $side in plugin | plain) ;; floor) checkside=plugin; prefix=floor- ;; *) flag=-p; checkside=plugin; prefix=$side- ;; esac
for step in $steps; do
  case $step in [0-9]) [ "$step" -lt "$first" ] && continue ;; esac
  echo "$(date -u +%H:%M:%SZ) request $step: start" >> "$log"
  (cd "$R" && sh trials/run.sh $flag "$run" "trials/prompts/outcome-$step.md" < /dev/null) >> "$log" 2>&1
  status=$?
  echo "$(date -u +%H:%M:%SZ) request $step: exit $status" >> "$log"
  python3 "$C/checks.py" "$checkside" "$dir" "$prefix$step" >> "$log" 2>&1
  if [ "$checkside" = plugin ]; then
    (cd "$dir" && . "$T/$run.out/env.sh" && make check > "$C/results/$side-$step-tests.log" 2>&1); t=$?
  else
    (cd "$dir" && python3 -m unittest discover -s tests -t . > "$C/results/$side-$step-tests.log" 2>&1); t=$?
  fi
  echo "own tests after $step: exit $t; commits: $(git -C "$dir" rev-list --count HEAD); uncommitted: $(git -C "$dir" status --short | wc -l | tr -d ' ')" >> "$log"
  ls ~/.local/bin | grep -v '^claude$' | sed 's/^/HOME BIN: /' >> "$log"
  [ $status -eq 0 ] || { echo "stopped after request $step" >> "$log"; exit $status; }
done
echo "chain done" >> "$log"
