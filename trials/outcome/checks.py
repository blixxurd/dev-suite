"""Hidden checks for the outcome test: brief B's two link checkers after each request.

usage: python3 checks.py <plugin|plain> <project folder> <label> [--snapshot]

Runs the project's command on folders made here, and on the fixed folders in corpus/.
--snapshot records what the command reports on corpus/ before any request; every later
run compares against that record. Results go to results/<side>-<label>.json, and a
table is printed. Standard library only, and Python 3.9, like the plain project.
"""
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
CORPUS = HERE / "corpus"


def command(side, project):
    if side == "plugin":
        return [str(project / ".venv" / "bin" / "mdlinkcheck")], {}
    base = project / "src" if (project / "src" / "mdlinkcheck").is_dir() else project
    return [sys.executable, "-m", "mdlinkcheck"], {"PYTHONPATH": str(base)}


def run(cmd, extra_env, args, cwd):
    env = dict(os.environ, **extra_env)
    try:
        p = subprocess.run(cmd + args, cwd=str(cwd), env=env, capture_output=True, text=True, timeout=60)
        return p.returncode, p.stdout, p.stderr
    except Exception as e:  # a command that is missing or hangs is a failed check, not a crash here
        return None, "", repr(e)


FINDING = re.compile(r"([^\s:'\"=,]+\.(?:md|MD|markdown)):(\d+)")


def findings(out, folder):
    """(path relative to the folder, line) for every file:line in the text output."""
    text = out.replace(str(folder) + os.sep, "")
    found = set()
    for path, line in FINDING.findall(text):
        found.add((path[2:] if path.startswith("./") else path, int(line)))
    return found


def json_findings(out, folder):
    """(path, line) pairs from any JSON objects that carry a .md path and a line number."""
    try:
        data = json.loads(out)
    except ValueError:
        return None
    pairs = set()

    def walk(node, inherited=None):
        if isinstance(node, dict):
            path = next((v for k, v in node.items() if isinstance(v, str) and ("file" in k.lower() or "path" in k.lower() or "source" in k.lower()) and re.search(r"\.(md|MD|markdown)$", v)), inherited)
            line = next((v for k, v in node.items() if "line" in k.lower() and isinstance(v, int) and not isinstance(v, bool)), None)
            if path and line is not None:
                p = path.replace(str(folder) + os.sep, "")
                pairs.add((p[2:] if p.startswith("./") else p, line))
            for v in node.values():
                walk(v, path)
        elif isinstance(node, list):
            for v in node:
                walk(v, inherited)

    walk(data)
    return pairs


def write(root, files):
    if root.exists():
        shutil.rmtree(root)
    for rel, text in files.items():
        f = root / rel
        f.parent.mkdir(parents=True, exist_ok=True)
        f.write_text(text, encoding="utf-8")
    return root


def main():
    side, project, label = sys.argv[1], Path(sys.argv[2]).resolve(), sys.argv[3]
    snapshot = "--snapshot" in sys.argv[4:]
    cmd, extra = command(side, project)
    work = HERE / "tmp" / side
    work.mkdir(parents=True, exist_ok=True)
    checks = []

    def check(group, name, ok, detail=""):
        checks.append({"group": group, "check": name, "pass": bool(ok), "detail": detail})

    def go(folder, *args):
        return run(cmd, extra, [str(folder)] + list(args), work)

    # Basics from the brief, which no request changes.
    clean = write(work / "clean", {"a.md": "# A\n\n[b](b.md)\n", "b.md": "# B\n"})
    code, out, err = go(clean)
    check("basics", "clean folder exits 0", code == 0, f"exit {code}")
    code, out, err = go(work / "no-such-folder")
    check("basics", "missing folder exits 2", code == 2, f"exit {code}")
    code, out, err = go(clean, "--nope")
    check("basics", "unknown flag exits 2", code == 2, f"exit {code}")
    code, out, err = run(cmd, extra, [], work)
    check("basics", "no folder exits 2", code == 2, f"exit {code}")

    # The fixed folders: what each reported before the requests must still be reported.
    snap_file = HERE / f"snapshot-{side}.json"
    now = {}
    for folder in sorted(CORPUS.iterdir()):
        code, out, err = go(folder)
        jcode, jout, jerr = go(folder, "--json")
        now[folder.name] = {"exit": code, "findings": sorted(findings(out, folder)), "json_exit": jcode,
                            "json_findings": None if json_findings(jout, folder) is None else sorted(json_findings(jout, folder))}
    if snapshot:
        snap_file.write_text(json.dumps(now, indent=1))
    before = json.loads(snap_file.read_text())
    for name, was in before.items():
        cur = now[name]
        lost = sorted(set(map(tuple, was["findings"])) - set(map(tuple, cur["findings"])))
        gained = sorted(set(map(tuple, cur["findings"])) - set(map(tuple, was["findings"])))
        check("regression", f"{name}: same findings as before the requests", not lost and not gained, f"lost {lost} gained {gained}")
        check("regression", f"{name}: same exit code as before", cur["exit"] == was["exit"], f"{was['exit']} -> {cur['exit']}")
        check("regression", f"{name}: --json still parses", cur["json_findings"] is not None, "")

    # Request 1: hidden folders are checked, except .git.
    r1 = write(work / "r1", {
        ".github/PULL_REQUEST_TEMPLATE.md": "# PR\n\nSee [the guide](missing-a.md).\n",
        "docs/.hidden/page.md": "# P\n\n[x](missing-b.md)\n",
        ".git/notes.md": "# N\n\n[y](missing-git.md)\n",
        "top.md": "# Top\n\n[ok](.github/PULL_REQUEST_TEMPLATE.md)\n",
    })
    code, out, err = go(r1)
    f = findings(out, r1)
    check("r1 hidden folders", ".github file's broken link listed with file and line", (".github/PULL_REQUEST_TEMPLATE.md", 3) in f, str(sorted(f)))
    check("r1 hidden folders", "nested hidden folder checked too", ("docs/.hidden/page.md", 3) in f, str(sorted(f)))
    check("r1 hidden folders", ".git is still skipped", "missing-git" not in out and not any(p.startswith(".git/") for p, _ in f), "")
    check("r1 hidden folders", "exit 1", code == 1, f"exit {code}")
    r1b = write(work / "r1b", {".git/x.md": "[y](gone.md)\n", "top.md": "# Top\n"})
    code, out, err = go(r1b)
    check("r1 hidden folders", "a broken link only under .git exits 0", code == 0, f"exit {code}")

    # Request 2: --exclude GLOB, repeatable; excluded files aren't checked, links to them stay good.
    r2 = write(work / "r2", {
        "a.md": "# A\n\n[d](drafts/d.md)\n[gone](gone.md)\n",
        "drafts/d.md": "# D\n\n[n](nowhere.md)\n",
        "drafts/sub/e.md": "# E\n\n[n](nowhere2.md)\n",
        "notes.md": "# N\n\n[x](x-missing.md)\n",
    })
    code, out, err = go(r2, "--exclude", "drafts/**")
    f = findings(out, r2)
    check("r2 exclude", "option accepted", code in (0, 1), f"exit {code} {err.strip()[:120]}")
    check("r2 exclude", "a file outside the glob is still checked", ("a.md", 4) in f and ("notes.md", 3) in f, str(sorted(f)))
    check("r2 exclude", "an excluded file is not checked", not any(p == "drafts/d.md" for p, _ in f) and "nowhere.md" not in out, str(sorted(f)))
    check("r2 exclude", "drafts/** reaches a nested file", not any(p == "drafts/sub/e.md" for p, _ in f) and "nowhere2.md" not in out, str(sorted(f)))
    check("r2 exclude", "a link to an excluded file still counts as good", ("a.md", 3) not in f, str(sorted(f)))
    check("r2 exclude", "exit 1 while something checked is broken", code == 1, f"exit {code}")
    code, out, err = go(r2, "--exclude", "drafts/**", "--exclude", "notes.md")
    f = findings(out, r2)
    check("r2 exclude", "repeatable", code == 1 and ("a.md", 4) in f and not any(p == "notes.md" for p, _ in f), f"exit {code} {sorted(f)}")
    code, out, err = go(r2, "--exclude", "drafts/**", "--exclude", "notes.md", "--exclude", "a.md")
    check("r2 exclude", "exit 0 when only excluded files are broken", code == 0, f"exit {code}")

    # Request 3: a broken heading link is a warning (exit 0); --strict fails it; file links still exit 1.
    r3h = write(work / "r3h", {"a.md": "# A\n\n## Real\n\n[ok](#real)\n[bad](#nope)\n[bad2](b.md#missing)\n", "b.md": "# B\n"})
    code, out, err = go(r3h)
    f = findings(out, r3h)
    check("r3 warnings", "heading-only breaks exit 0", code == 0, f"exit {code}")
    check("r3 warnings", "heading breaks are still listed", ("a.md", 6) in f and ("a.md", 7) in f, str(sorted(f)))
    code, out, err = go(r3h, "--strict")
    check("r3 warnings", "--strict exits 1", code == 1, f"exit {code} {err.strip()[:120]}")
    code, out, err = go(r3h, "--json")
    jf = json_findings(out, r3h)
    check("r3 warnings", "--json exits 0 and still carries them", code == 0 and jf is not None and ("a.md", 6) in jf and ("a.md", 7) in jf, f"exit {code} {sorted(jf) if jf else jf}")
    r3f = write(work / "r3f", {"a.md": "# A\n\n[bad](#nope)\n[gone](sub/gone.md)\n", "sub/x.md": "# X\n\n[g2](g2.md)\n"})
    code, out, err = go(r3f)
    check("r3 warnings", "a broken file link still exits 1", code == 1, f"exit {code}")

    # Request 4: --format github.
    code, out, err = go(r3f, "--format", "github")
    lines = out.splitlines()
    has = lambda pat: any(re.match(pat, l) for l in lines)
    check("r4 github", "option accepted", code in (0, 1), f"exit {code} {err.strip()[:120]}")
    check("r4 github", "heading break is a ::warning with relative path and line", has(r"^::warning file=a\.md,line=3::\S"), "\n".join(lines[:6]))
    check("r4 github", "file break is an ::error", has(r"^::error file=a\.md,line=4::\S"), "")
    check("r4 github", "path relative to the folder, in a subfolder", has(r"^::error file=sub/x\.md,line=3::\S"), "")
    check("r4 github", "exit 1 with a broken file link", code == 1, f"exit {code}")
    code, out, err = go(r3h, "--format", "github")
    warns = [l for l in out.splitlines() if l.startswith("::warning ")]
    check("r4 github", "heading-only: exit 0 and two ::warning lines", code == 0 and len(warns) == 2, f"exit {code}, {len(warns)} warnings")
    code, out, err = go(r3h, "--format", "github", "--strict")
    check("r4 github", "with --strict exits 1", code == 1, f"exit {code}")

    results = HERE / "results"
    results.mkdir(exist_ok=True)
    (results / f"{side}-{label}.json").write_text(json.dumps(checks, indent=1))
    shutil.rmtree(work, ignore_errors=True)
    groups = {}
    for c in checks:
        g = groups.setdefault(c["group"], [0, 0])
        g[0] += c["pass"]
        g[1] += 1
    print(f"{side} {label}: " + ", ".join(f"{g} {p}/{n}" for g, (p, n) in groups.items()))
    for c in checks:
        if not c["pass"]:
            print(f"  fail  {c['group']}: {c['check']}  ({c['detail'][:160]})")


if __name__ == "__main__":
    main()
