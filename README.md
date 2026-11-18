# dev

A [Claude Code](https://code.claude.com) plugin that plans, builds and ships new software projects the way a good developer builds them.

You give it a brief. It writes a plan and asks for your approval once. Then it works on its own:
- a walking skeleton with a commit gate;
- the build, one proven commit at a time;
- an independent review of everything it wrote;
- a report that shows, for each thing your brief asked for, where it is and how it is proven.

It commits as it goes, and never pushes, publishes or deploys.

## Install

In Claude Code:

```
/plugin marketplace add blixxurd/dev-suite
/plugin install dev@dev-suite
```

Or from a shell, `claude plugin marketplace add blixxurd/dev-suite` and then `claude plugin install dev@dev-suite`.

You also need git and make. Each project needs whatever runtime its plan picks. The plan checks what your machine has, and installing anything more is a stop and ask. Tested with Claude Code 2.1.325.

## Use

1. **Write a brief.** In an empty folder, save a few sentences or a page as `brief.md`: what to build, who it's for, and anything already decided.
2. **Plan it.** Run `/dev:plan brief.md`. It reads the brief and looks at any real data, API or tool the brief names. It checks the runtimes on your machine, then writes `GAMEPLAN.md`:
   - what will be built;
   - every assumption, with each guess about something the brief leaves open marked "to confirm";
   - the design;
   - the build order;
   - the risks.

   Then it stops and asks for approval.
3. **Approve it.** Reply "Approved as written.", or approve with changes, or with a limit such as "stop after the skeleton". This is the only stop. Approving settles the plan's "to confirm" guesses, apart from any you change. From here it runs to a release on its own, and stops early only for:
   - something irreversible or outward-facing;
   - a credential, a runtime install or a large download your approval didn't cover;
   - a requirement it can't meet.
4. **Read the report.** The run ends with `REPORT.md` and a local `ship-1` tag. It lists every call it made that you may want the other way.

If a build is interrupted, `/dev:build` carries on in a new session from the plan's Status.

**After the first release,** ask Claude Code for changes in plain words; the plugin need not be loaded. The project's own `CLAUDE.md` and commit gate carry the way of working:
- the interface changes first;
- a test that fails before the change;
- one commit with its proof;
- a note of any call the request left open.

Use the plugin again for `/dev:ship`, which reviews everything since the last release and tags the next one, or for a new brief.

The plugin doesn't change your permission settings, so Claude Code asks for permission as it always does. A first build runs many commands, so expect to approve a lot of them, or allow the routine ones for the project.

## Commands

You normally type only `/dev:plan`; each skill starts the next.

| Command | What it does |
|---|---|
| `/dev:plan <brief>` | Brief to `GAMEPLAN.md`, then the one approval, then the first build through to a release |
| `/dev:scaffold` | The approved plan to a walking skeleton, with a commit gate it has seen refuse each rule |
| `/dev:build` | The plan's build order, one proven commit per step; also carries on an interrupted build |
| `/dev:review` | Everything since the last release, reviewed by an agent that didn't write it; each finding fixed or decided |
| `/dev:ship` | Review, prune, the slow checks from a fresh clone, `REPORT.md` and a local `ship-N` tag |
| `/dev:standards` | The ten rules for writing code, loaded before code is written or reviewed |

## What a project gets

- **`GAMEPLAN.md`**: the plan, and a Status line any new session can pick up from.
- **`docs/brief.md` and `docs/decisions.md`**: the brief word for word, and each call made after approval with its reason.
- **`CLAUDE.md`**: short, written for agents, with the five lines every change follows.
- **A commit gate:**
  - `make check` runs every tool the plan picked to enforce the rules, plus the fast tests.
  - A git pre-commit hook runs it before every commit.
  - A commit-msg hook holds commit subjects to Conventional Commits.
- **Defaults for a service:** a long-running service gets a container, a health check and config from the environment. For any other kind of project, the plan works out the equivalents and lists them for approval.
- **`REPORT.md` at each release:** a row per requirement with its proof, the calls to confirm, the trade-offs, and what the review found and what became of each finding.

## The rules it builds by

1. One home for every fact.
2. Pure core, I/O at the edges.
3. Validate at the boundary, fail on one path.
4. Contract first.
5. Tests pin behavior someone relies on.
6. Prove every change with proof that fits it.
7. Build the structure, leave out the extras.
8. Cut scope, never compress code.
9. Leave the gate alone.
10. Write down the calls.

Each comes with its reason in [the standards skill](plugin/skills/standards/SKILL.md).

## What to expect

These are from testing on two small briefs, a web service and a command-line tool. Each was built with and without the plugin, and every run was scored line by line against [a checklist](trials/checklist.md) of these rules. It was one run of each, so read the numbers as leads, not proof.
- **Rules met:** with the plugin, 83 to 89% of the checklist lines were met in full, and one line was missed outright across three runs. Plain Claude Code met 14 to 24% in full.
- **Cost:** a first build with the plugin took 59 to 88 minutes and $21 to $26 of usage on Claude Opus. Without it, a build took 26 to 74 minutes and cost $8 to $10.
- **Later changes:** four small, clear changes to a finished project were just as correct with plain Claude Code. On the plugin-built project, each change cost two to two and a half times as much, because it keeps the project's contracts, tests and docs true and proves it.
- **What review missed:** most often, behavior that no test pinned.

## Working on it

Needs Claude Code (`claude` on the path), git, make, jq and a POSIX shell.

```sh
make setup   # once per clone: switches on the commit gate
make check   # what the gate runs before every commit
make help    # every command
```

`CLAUDE.md` is for agents working on this repo. To try a change to the plugin without installing it, run `claude --plugin-dir ./plugin`.

### Trials

`trials/` measures the plugin. A trial builds one of the two test briefs in a new folder under `~/Projects/dev-suite-trials/` (set `TRIALS_HOME` to move it), in a headless Claude Code session. **That session runs with permission prompts off**, and it costs about as much as a build.

```sh
sh trials/run.sh -b trials/service-brief.md baseline-a-1 trials/prompts/baseline.md   # without the plugin
sh trials/run.sh -b trials/service-brief.md -p trial-a-1 trials/prompts/plan.md       # with it: -p goes on every call of the run
sh trials/after.sh -a trial-a-1 > "$TRIALS_HOME/trial-a-1.out/after.txt"              # once it has ended
```

Each run is kept apart from the rest of the machine:
- What a session returns goes beside the run's folder, in `<run>.out/`.
- What Go, npm, pip and uv download goes in `<run>.cache/`, not your home folder. Load `<run>.out/env.sh` before running the finished project's own commands.
- A session is told to keep to its folder, but nothing stops it from leaving. So `after.sh` reads its transcripts afterwards and reports what it did beyond the folder.

A finished run is scored against [the checklist](trials/checklist.md) by an agent given [the scoring brief](trials/scoring.md) and nothing about what to expect.

## Layout

| Path | What |
|---|---|
| `plugin/` | The plugin: its skills, the reviewer agent, and the templates every project starts from. Only this ships |
| `.claude-plugin/marketplace.json` | Lets Claude Code install the plugin from this repo |
| `scripts/` | The checks behind `make check` |
| `.githooks/` | This repo's commit gate: the same hooks the plugin gives every project |
| `trials/` | The test briefs, the trial runner, the checklist and the scoring brief |

## License

[MIT](LICENSE)
