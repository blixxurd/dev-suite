#!/bin/sh
# Proves each check in lint.sh: a copy of this repo passes as it is, and is refused,
# for the stated reason, once a violation is planted in it.
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cases=0
fail() {
  echo "test-lint: FAIL: $1" >&2
  exit 1
}

fresh_copy() {
  rm -rf "$tmp/repo"
  mkdir "$tmp/repo"
  (cd "$root" && tar cf - --exclude .git .) | (cd "$tmp/repo" && tar xf -)
}

# passes <what was done> <shell that does it>
passes() {
  fresh_copy
  (cd "$tmp/repo" && eval "$2")
  output=$(sh "$tmp/repo/scripts/lint.sh" 2>&1) || fail "lint refused the repo with $1: $output"
  cases=$((cases + 1))
}

# refuses <what is planted> <words lint must say> <shell that plants it>
refuses() {
  fresh_copy
  (cd "$tmp/repo" && eval "$3")
  if output=$(sh "$tmp/repo/scripts/lint.sh" 2>&1); then fail "lint passed with $1 planted"; fi
  printf '%s\n' "$output" | grep -q -- "$2" || fail "with $1 planted, lint did not say '$2' but: $output"
  cases=$((cases + 1))
}

skills=plugin/skills
skill=$skills/standards/SKILL.md

passes 'nothing changed' ':'

refuses 'an oversized skill' 'over the limit' \
  "awk 'BEGIN { for (i = 0; i < 2000; i++) print \"word\" }' >> $skill"

refuses 'a skill whose name is not its folder' 'frontmatter name' \
  "mkdir $skills/renamed && cp $skill $skills/renamed/SKILL.md"

refuses 'a skill other skills cannot load' 'disable-model-invocation' \
  "mkdir $skills/locked && printf '%s\n' '---' 'name: locked' 'description: x' 'disable-model-invocation: true' '---' > $skills/locked/SKILL.md"

refuses 'a link to a missing file' 'does not exist' \
  "echo 'See [the notes](docs/missing.md).' >> README.md"

refuses 'a link to a file git ignores' 'git ignores' \
  "git init -q . && echo 'notes' > private.md && echo '/private.md' >> .gitignore && echo 'See [the notes](private.md).' >> README.md"

passes 'plugin paths that are there' \
  "printf '%s\n' 'Copy \${CLAUDE_PLUGIN_ROOT}/skills/scaffold/templates/pre-commit, then read \${CLAUDE_SKILL_DIR}/SKILL.md.' >> $skill"

refuses 'a plugin path that is not there' 'in the plugin, which does not exist' \
  "printf '%s\n' 'Copy \${CLAUDE_PLUGIN_ROOT}/skills/missing-template.md into the project.' >> $skill"

refuses 'a path beside the skill that is not there' "points at 'missing-notes.md'" \
  "printf '%s\n' 'Read \${CLAUDE_SKILL_DIR}/missing-notes.md first.' >> $skill"

refuses 'a plugin variable where it is not filled in' 'only filled in' \
  "printf '%s\n' 'See \${CLAUDE_PLUGIN_ROOT}/skills/standards/SKILL.md' > $skills/standards/extra.md"

refuses 'a shell script that does not parse' 'does not parse' \
  "printf '%s\n' '#!/bin/sh' 'if then' > scripts/broken.sh"

refuses 'a hook that is not executable' 'not executable' \
  "chmod -x $skills/scaffold/templates/pre-commit"

refuses 'a service default named in a general skill' 'names a service default' \
  "echo 'Then build the Docker image.' >> $skill"

passes 'a service default named in its own file' \
  "mkdir -p $skills/plan && echo 'The artifact is a Docker image.' >> $skills/plan/service-defaults.md"

echo "test-lint: ok ($cases cases)"
