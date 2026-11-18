#!/bin/sh
# The checks on the plugin's own files that `claude plugin validate` does not make.
# Each problem is printed as  file:line: what is wrong.  Exits 1 if there was one.
# scripts/test-lint.sh plants a violation of every check here and expects it refused.
set -u
cd "$(dirname "$0")/.." || exit 2

# The plugin's own folder: what Claude Code loads and what ships. The rest of the repo
# is for working on it.
PLUGIN=plugin

# Size limits, in words. A line of prose has no fixed length, so a limit in lines
# could be met by joining lines.
SKILL_WORDS=1000
STANDARDS_WORDS=600
STANDARDS_FILE=$PLUGIN/skills/standards/SKILL.md

# The one file that may name the service defaults, and the words that give them away.
SERVICE_HOME=$PLUGIN/skills/plan/service-defaults.md
SERVICE_WORDS='docker|container|health.?check|controller|twelve.factor|12.factor|json logs'

TAB=$(printf '\t')
found=$(mktemp)
refs=$(mktemp)
trap 'rm -f "$found" "$refs"' EXIT

frontmatter_name() {
  awk '/^---$/ { blocks++; next } blocks == 1 && /^name:/ { sub(/^name:[ ]*/, ""); print; exit }' "$1"
}

# 1. Size, and a name that matches the folder or file it is addressed by.
for file in "$PLUGIN"/skills/*/SKILL.md "$PLUGIN"/agents/*.md; do
  [ -f "$file" ] || continue
  limit=$SKILL_WORDS
  [ "$file" = "$STANDARDS_FILE" ] && limit=$STANDARDS_WORDS
  words=$(wc -w < "$file" | tr -d ' ')
  if [ "$words" -gt "$limit" ]; then
    echo "$file: $words words, over the limit of $limit. Cut something or move it to a file beside the skill; do not compress the wording."
  fi
  case $file in
    "$PLUGIN"/skills/*) expected=$(basename "$(dirname "$file")") ;;
    *) expected=$(basename "$file" .md) ;;
  esac
  name=$(frontmatter_name "$file")
  if [ "$name" != "$expected" ]; then
    echo "$file: frontmatter name is '$name' but it is addressed as '$expected'"
  fi
done >> "$found"

# 2. Skills must stay loadable by other skills and by agents.
grep -H -n -E '^disable-model-invocation:[ ]*true' "$PLUGIN"/skills/*/SKILL.md 2>/dev/null |
  sed -E 's/^([^:]+:[0-9]+):.*/\1: disable-model-invocation stops the next skill and the reviewer from loading this one/' >> "$found"

# 3. Links between Markdown files resolve. Code spans and fenced blocks are skipped. In a git
#    repo only the files a clone would get are read, and a link to a file git ignores counts as
#    missing, because a clone won't have it.
in_git=false
git rev-parse --git-dir > /dev/null 2>&1 && in_git=true
markdown_files() {
  if $in_git; then git ls-files --cached --others --exclude-standard -- '*.md'
  else find . -path ./.git -prune -o -type f -name '*.md' -print | sed 's|^\./||'; fi
}
markdown_files | sort | while read -r file; do
  awk -v file="$file" '
    /^[ ]*```/ { fenced = !fenced; next }
    fenced { next }
    {
      line = $0
      gsub(/`[^`]*`/, "", line)
      while (match(line, /\]\([^)]*\)/)) {
        printf "%s\t%d\t%s\n", file, FNR, substr(line, RSTART + 2, RLENGTH - 3)
        line = substr(line, RSTART + RLENGTH)
      }
    }' "$file"
done > "$refs"
while IFS=$TAB read -r file line target; do
  case $target in
    http://* | https://* | mailto:* | '#'*) continue ;;
    *'<'* | *'{'*) continue ;; # a placeholder in a template
  esac
  path=${target%%#*}
  path=${path%% *}
  if [ ! -e "$(dirname "$file")/$path" ]; then echo "$file:$line: link to '$target', which does not exist"
  elif $in_git && git check-ignore -q "$(dirname "$file")/$path"; then echo "$file:$line: link to '$target', which git ignores, so a clone won't have it"; fi
done < "$refs" >> "$found"

# 4. Paths under the plugin's own folder resolve, and the variables that stand for it
#    appear only where Claude Code fills them in: SKILL.md and agent files.
for file in "$PLUGIN"/skills/*/SKILL.md "$PLUGIN"/agents/*.md; do
  [ -f "$file" ] || continue
  awk -v file="$file" -v plugin_root="$PLUGIN" '
    BEGIN {
      pattern = "[$][{]CLAUDE_(PLUGIN_ROOT|SKILL_DIR)[}]/[A-Za-z0-9_./-]*"
      skill_dir = file
      sub(/\/[^\/]*$/, "", skill_dir)
    }
    {
      line = $0
      while (match(line, pattern)) {
        ref = substr(line, RSTART, RLENGTH)
        base = (ref ~ /PLUGIN_ROOT/) ? plugin_root : skill_dir
        sub(/^[^}]*[}]\//, "", ref)
        sub(/[.]+$/, "", ref)
        printf "%s\t%d\t%s\t%s\n", file, FNR, base, ref
        line = substr(line, RSTART + RLENGTH)
      }
    }' "$file"
done > "$refs"
while IFS=$TAB read -r file line base path; do
  [ -e "$base/$path" ] || echo "$file:$line: points at '$path' in the plugin, which does not exist"
done < "$refs" >> "$found"
grep -r -n -F '${CLAUDE_' "$PLUGIN/skills" 2>/dev/null | grep -v "^$PLUGIN/skills/[^/]*/SKILL\.md:" |
  sed -E 's/^([^:]+:[0-9]+):.*/\1: a ${CLAUDE_...} variable is only filled in inside SKILL.md and agent files; here it would stay as written/' >> "$found"

# 5. Shell scripts parse, and the hooks are executable (git skips a hook that is not).
find . -path ./.git -prune -o -type f -print | sed 's|^\./||' | sort | while read -r file; do
  head -n 1 "$file" | grep -q '^#!/bin/sh' || continue
  error=$(sh -n "$file" 2>&1) || echo "$file: does not parse as shell: $error"
done >> "$found"
for file in .githooks/*; do
  [ -x "$file" ] || echo "$file: not executable, so git would skip it"
done >> "$found"

# 6. The service defaults are named in one file only.
for dir in "$PLUGIN/skills" "$PLUGIN/agents"; do
  [ -d "$dir" ] || continue
  grep -r -n -i -E "$SERVICE_WORDS" "$dir" | grep -v "^$SERVICE_HOME:" |
    sed -E "s|^([^:]+:[0-9]+):.*|\1: names a service default; those live only in $SERVICE_HOME|"
done >> "$found"

if [ -s "$found" ]; then
  cat "$found" >&2
  echo "lint: $(wc -l < "$found" | tr -d ' ') problem(s)" >&2
  exit 1
fi
echo "lint: ok"
