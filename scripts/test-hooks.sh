#!/bin/sh
# Proves the two hook templates the suite scaffolds, in a throwaway repo: a good commit
# goes through, and a bad subject, a failing check or a commit that is not what is on
# disk is refused.
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
templates=$root/plugin/skills/scaffold/templates

# Git hands a hook its own variables, GIT_INDEX_FILE among them, and this script runs
# from one. Cleared, so the git commands below act on the throwaway repo and no other.
unset $(git rev-parse --local-env-vars)
# The user's git settings (signing, templates, other hooks) stay out of the test.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cases=0
fail() {
  echo "test-hooks: FAIL: $1" >&2
  exit 1
}

mkdir "$tmp/repo"
cd "$tmp/repo"
git init -q -b main .
git config user.name 'Hook Test'
git config user.email 'hook-test@example.invalid'
mkdir .githooks
cp "$templates/pre-commit" "$templates/commit-msg" .githooks/
# The stand-in for a project's checks: fails while a file named BROKEN exists, and
# fails if git's hook variables reached it (the pre-commit template must clear them).
printf 'check:\n\t@test ! -e BROKEN\n\t@test -z "$${GIT_INDEX_FILE:-}"\n' > Makefile
echo one > tracked.txt
git config core.hooksPath .githooks
git add -A

# commit <subject> [options for git commit]: what git and the hooks said is kept in $tmp/out.
commit() {
  subject=$1
  shift
  git commit -q --allow-empty "$@" -m "$subject" > "$tmp/out" 2>&1
}
# The pre-commit hook's own refusal, as against a refusal by the checks it runs.
not_on_disk() { grep -q '^pre-commit: refused' "$tmp/out"; }
# names <file>: the refusal lists that file.
names() { grep -q -x -F -e "  $1" "$tmp/out"; }

commit 'feat: first commit' || fail 'a good commit was refused'
cases=$((cases + 1))

if commit 'added some stuff'; then fail 'a commit with a bad subject went through'; fi
cases=$((cases + 1))

: > BROKEN
git add BROKEN
if commit 'fix: with the checks failing'; then fail 'a commit went through while make check was failing'; fi
if not_on_disk; then fail 'the failing checks were not what refused the commit'; fi
git rm -q -f BROKEN
cases=$((cases + 1))

# Staged one way and then changed again on disk: the checks would read the second version
# and the commit would hold the first.
echo two > tracked.txt
git add tracked.txt
echo three > tracked.txt
if commit 'fix: staged, then changed again'; then fail 'a commit went through that held an older version of a file than the one on disk'; fi
not_on_disk && names tracked.txt || fail 'the refusal did not name the file that differs'
cases=$((cases + 1))

# `git commit -a` gives the hook an index of its own, named by GIT_INDEX_FILE. A hook that
# compared the files with the usual index would refuse this.
commit 'fix: the same change, committed with -a' -a || fail 'a commit made with -a was refused'
cases=$((cases + 1))

: > stray.txt
if commit 'fix: with a file that was never added'; then fail 'a commit went through while a file on disk was missing from it'; fi
not_on_disk && names stray.txt || fail 'the refusal did not name the file that was never added'
cases=$((cases + 1))

echo stray.txt > .gitignore
git add .gitignore
commit 'chore: ignore the stray file' || fail 'an ignored file stopped a commit'
cases=$((cases + 1))

[ "$(git rev-list --count HEAD)" = 3 ] || fail 'the refused commits left something behind'

# The subject pattern, straight through the hook.
subject_ok() {
  printf '%s\n' "$1" > "$tmp/message"
  sh .githooks/commit-msg "$tmp/message" 2> /dev/null
}
accepts() {
  subject_ok "$1" || fail "refused a good subject: $1"
  cases=$((cases + 1))
}
refuses() {
  if subject_ok "$1"; then fail "accepted a bad subject: $1"; fi
  cases=$((cases + 1))
}
accepts 'feat(api): list earthquakes newest first'
accepts 'fix!: drop the old flag'
accepts 'docs: say how to run a trial'
accepts "Merge branch 'main' into topic"
accepts "Merge remote-tracking branch 'origin/main'"
accepts "Merge branches 'o1' and 'o2' into o3"
accepts 'Revert "feat(api): list earthquakes newest first"'
accepts "Revert \"Merge branch 'topic'\""
accepts 'Reapply "fix: b"'
refuses 'Merge the two helpers into one'
refuses 'Revert "anything at all, no type"'
refuses 'Added the list endpoint'
refuses 'feat:no space after the colon'
refuses 'feat(): an empty scope'
refuses 'feature: a type that is not on the list'
refuses 'feat: '

echo "test-hooks: ok ($cases cases)"
