# Trial checklist

One line per rule of the way of building that shows in a built project, plus what every built project contains. Every trial run is scored against it, with the plugin or without. It was committed before the first run, so no run could shape it.

## Scoring

Each line gets **yes**, **partly**, **no** or **n/a**, and its evidence: a file and line, a commit, or a command with its output. A line with no evidence cannot score yes. An n/a says why the rule had no occasion to show.

Lines are scored on substance. A run without the plugin that keeps its plan under another name still has a plan, so "the plan", "the decision log" and "the report" mean whichever file plays that part. Only group F scores where things are.

Every run is told by the runner (`trials/run.sh`) to add no remote, push, publish or deploy nothing, and install nothing system-wide. Where a line turns on one of those, its score rests on the rest of the line and the evidence says so.

A result is one file, `trials/results/<run>.md`, in three parts:

1. The run: brief, with or without the plugin, date, session ids, models, turns, time, cost, and each time it stopped and why.
2. One row per line below: ID, score, evidence.
3. What the run suggests changing in the suite, including anything found by reading the code that the run's own review missed.

## W. It does what the brief asks

| ID | Rule | Evidence |
|---|---|---|
| W1 to Wn | Each numbered requirement in the brief works when exercised by hand against the artifact built from a fresh clone. One line per requirement, using the probes below | The commands and their output |
| Wx | Nothing the brief rules out was built | What was found |

**Probes for brief A**, fixed here so that every run of it gets the same ones:

1. After one refresh the record holds the feed's events. After a second the count is unchanged. After a refresh from a copy of the feed in which one event has a new magnitude and a later `updated`, that event shows the new values. Where a build doesn't let the source be set, its own test for this is read instead. Noted but not scored: what happens when an event comes back under a new preferred id with the old one in `ids`.
2. The list is newest first. It filters by minimum magnitude, by a time range, and by both. A bad value (a magnitude of `abc`, an end before the start) gets a client error shaped like every other error.
3. A summary of a range gives the count, the largest and a count per band, and the bands add up to the count or the difference is explained. Events with a negative or missing magnitude don't break it. An empty range answers.
4. With the source unreachable, the list and the summary still answer, and a refresh fails with a clear error and leaves the record as it was.

**Probes for brief B:**

1. In a folder of files with known good and broken links, every broken link to a file and to a heading (in the same file and in another) is listed with its file and line, and no good link is. Noted but not scored: links inside code blocks, reference-style links, and headings that repeat.
2. With a web link whose host doesn't resolve, the result is the same and comes back at once. The output says how many web links there were.
3. The default output can be read without explanation. The `--json` output parses with `jq` and carries the same findings.
4. Exit code 0 on a clean folder, 1 on a broken one, and 2 with no folder, an unknown flag or a folder that doesn't exist.
5. It is Python, installs into a clean environment from a fresh clone, and runs as a command.

## P. Plan

| ID | Rule | Evidence |
|---|---|---|
| P1 | A plan was written and committed before any code | The commit that adds the plan against the one that adds the first source file |
| P2 | Every requirement in the brief has a row saying how it is met and what proves it | The plan's table against the brief |
| P3 | What was assumed is written ahead of the approval: the kind of project and what follows from it, each reading of something the brief leaves open, whether it is a long-running service, whether it needs storage that outlives the process, and any runtime the machine lacks | The plan |
| P4 | Decisions carry their why, including what was ruled out, and risks carry what is done about them | The plan |
| P5 | The real thing was probed before coding, and the plan says when and what it showed. For brief A: negative magnitudes, empty fields, events with several ids, values revised after publication | The plan |
| P6 | Test fixtures are cut from the real data | The fixture files, with real ids in them |
| P7 | The build order is steps with a "done when", and the skeleton, the fixtures and the contracts come first | The plan against `git log` |
| P8 | No cut list, because neither brief has a hard limit | The plan |
| P9 | The approval is recorded in the plan: who, when and in what words | The plan's status |
| P10 | The status was kept current during the build and is true at the end | `git log` on the plan; the status against the repo |
| P11 | The brief is kept word for word | `diff` against the trial brief |

## A. Running on its own

| ID | Rule | Evidence |
|---|---|---|
| A1 | It asked the driver nothing before writing the plan | The run's output |
| A2 | The only input after the brief was one approval | Driver messages, counted |
| A3 | After the approval it ran until the work was shipped or a step was reported blocked. It stopped for nothing except a requirement that can't be met, something irreversible or outward-facing, or a credential or a large download | The run's output |
| A4 | Calls made after the approval are in the decision log: dated, with the call, the why, and settled or to confirm | The log |
| A5 | Where the brief leaves product behavior open, it took the reading easiest to undo, logged it "to confirm" and kept going | The entries, and the report's list of them |
| A6 | After three failed attempts at the same failure it stopped and reported the step blocked | The run's output. n/a if it never got stuck |
| A7 | Stopped mid-build and started again in a new session, it carried on from the plan's status without redoing or skipping a step (trial B) | The commits before and after the stop |

## G. Gate

For G3 to G9 the evidence is the config that enforces the rule and one planted violation that the gate refuses.

| ID | Rule | Evidence |
|---|---|---|
| G1 | `make setup && make check` passes in a fresh clone | The output |
| G2 | The gate lives in the repo and one command switches it on: a versioned pre-commit hook runs the fast checks, and a commit-msg hook checks the subject | `.githooks/`, `make setup`, and a bad commit tried |
| G3 | Strict typing | |
| G4 | Small units: about 40 lines for a function and 200 for a file, or the plan's limits for this kind of project | Also the longest function and file, measured |
| G5 | No dead code and no unused exports | |
| G6 | No suppression unless it covers one line and says why, and every one in the code is in the decision log | Also a search for suppression markers |
| G7 | No TODO or FIXME left behind | Also a search |
| G8 | Lint and formatting | |
| G9 | Code that no longer matches its contract | |
| G10 | The gate was proven when it was set up: each violation above was planted and refused, with the results in that commit's body | The scaffold commit |
| G11 | The gate was never loosened to get past a failure: no rule switched off, no test deleted or skipped | `git log -p` on the gate's config and the tests after the scaffold commit |
| G12 | Every commit subject is a Conventional Commit | The commit-msg hook run over every subject |
| G13 | The gate is green at every commit, not only the last | `make check` at each commit in a scratch clone |

## C. Code

Scored by reading. A "no" or "partly" cites file and line.

| ID | Rule | Evidence |
|---|---|---|
| C1 | Every fact has one home: a value, a shape or a rule is defined once and read from there, and a literal that means something has a name. Similar code is extracted the third time, not the first | Duplicates and one-caller abstractions found |
| C2 | The core is pure: logic takes values and returns values, and network, disk, clock and environment are touched only at the edges | What the logic modules import |
| C3 | Input is checked once where it enters (a request, a file, the environment, someone else's API) and typed values go inward | Where each is validated |
| C4 | Every failure leaves by one path, and errors look the same to callers and in the logs | Two different failures, compared |
| C5 | Split by concern and layered from the first code commit. For a service: controller, service, repository. For another kind: the plan's equivalent | The tree at the skeleton commit and at the end |
| C6 | Tests go through the public surface, with data cut from the real thing | The test files |
| C7 | A bug was fixed with a test that failed first | The commit. n/a if no bug was fixed |
| C8 | Nothing was built that nobody asked for: no extra feature, option or endpoint | Extras, listed against the brief |
| C9 | Nothing was compressed to fit a limit: no joined lines, shortened names or dropped checks | Reading |
| C10 | Comments say why, not what | A sample |

## H. History

| ID | Rule | Evidence |
|---|---|---|
| H1 | One commit per build step, in the plan's order | `git log` against the plan |
| H2 | Each commit body carries proof that fits the change: identical output for a refactor, a test that used to fail for new behavior, a fresh clone at ship | The bodies |
| H3 | A refactor has its own commit | `git log` |
| H4 | For each interface, the contract was committed before the code on either side of it | The commit that adds each |

## I. Interfaces

| ID | Rule | Evidence |
|---|---|---|
| I1 | Every interface, between parts or to the outside, has a contract file in the default format for its kind, or the plan says why not. The defaults: OpenAPI for an HTTP API; the command definition plus JSON Schema for `--json` output; JSON Schema for files, config and events; the typed exported interface for a library | The files |
| I2 | The contract is the one home for its shapes: code is generated from it or checked against it | Where, and the check |
| I3 | A view that people can read is rendered from the contract | The command and what it produces |

## B. Bootstrap

| ID | Rule | Evidence |
|---|---|---|
| B1 | The runtime is the newest LTS that every dependency supports. It is pinned, and the plan records the date it was checked | The pins; what was LTS on that date |
| B2 | Dependency versions were looked up, not recalled | Three pinned versions against the registry |
| B3 | Every dependency has a written reason | The plan's stack table against the manifest |
| B4 | One module reads the environment and fails fast on a bad value, and an example env file is committed | A start with a bad value |
| B5 | The first code commit is a walking skeleton: it starts, has one real test and passes the gate | That commit, checked out |
| B6 | A Makefile is the task runner: `make help` lists the commands, and `help`, `setup`, `check`, `test` and `build` exist | `make help` |
| B7 | Git starts with a Conventional Commit. There is no remote, no CI and no hosting config | `git remote -v`; the tree |

## K. Defaults for the kind of project

| ID | Rule | Evidence |
|---|---|---|
| K1 | It builds from a fresh clone into a portable artifact: a Docker image for anything that stays running, the installable package for a command-line tool or a library | The build, from a clone |
| K2 | Service: the container runs as a user other than root | `docker inspect`, or `id -u` inside it |
| K3 | Service: it takes its config from the environment only, answers a health check, and logs JSON lines to stdout | The running container |
| K4 | Another kind: the plan lists the equivalent of each service default, or "no equivalent" and why, and nothing service-shaped was built that the kind doesn't need | The plan's assumptions; the tree |

## S. Security

| ID | Rule | Evidence |
|---|---|---|
| S1 | Env files are git-ignored and only the example is committed | `git ls-files`; `git check-ignore .env` |
| S2 | A dependency audit ran at ship and not in the commit gate. Known high-severity issues are fixed, or listed in the report when no fix exists | The report; the audit run again |

## D. Docs

| ID | Rule | Evidence |
|---|---|---|
| D1 | CLAUDE.md is for agents and has the template's sections in the template's order, with empty ones left out | The file against the template; its line count |
| D2 | Every line of CLAUDE.md is something an agent can't get from the code or from a tool: no mechanical rule restated, no how-to-run, no decisions, no copy of the standards | Line by line |
| D3 | The README is for people and is true: its commands work as written in a fresh clone | The commands, run |
| D4 | The standards are not copied into the project | A search for the rules' titles |

## F. Where things are

| ID | Rule | Evidence |
|---|---|---|
| F1 | `README.md`, `CLAUDE.md`, `GAMEPLAN.md`, `Makefile`, `.githooks/`, `docs/brief.md` and `docs/decisions.md` exist, and `REPORT.md` after a ship | `ls` |
| F2 | One contract file per interface, where CLAUDE.md says it is | The paths |

## R. Review and ship

| ID | Rule | Evidence |
|---|---|---|
| R1 | Everything changed since the last ship was reviewed by an agent that did not write it | The report; the run's agent counts and models |
| R2 | The review covered rule breaks, things to simplify, and scope against the brief | The findings |
| R3 | Each finding cites a file and line plus the rule broken or a scenario that fails, or the result is "nothing found" | The findings |
| R4 | Each finding was fixed in its own commit, or decided against with the reason recorded. There was at most one re-review | The report's review table; the commits |
| R5 | It was pruned before ship: nothing is left that no requirement and no agent needs, and the plan, the brief, the decision log and CLAUDE.md are kept | The tree |
| R6 | The slow checks ran at ship from a fresh clone: the gate, the artifact build and the audit | The report; the checks run again |
| R7 | The report has what was built in two sentences, a row per requirement with where it is and its proof, the calls to confirm, the trade-offs, anything blocked or left out, the review's findings with what happened to each, and the output of the ship checks | `REPORT.md` |
| R8 | Every proof the report names holds when run again | The proofs, run |
| R9 | The ship is marked with an annotated tag, `ship-N` | `git tag -n` |

## N. Changing a finished project

For the two change runs. This is the floor that every later change has to meet.

| ID | Rule | Evidence |
|---|---|---|
| N1 | After the change the gate is green in a fresh clone | The output |
| N2 | If the change touched an interface, its contract changed before the code | The commits |
| N3 | A call someone could reasonably have made differently was logged | The decision log's diff |
| N4 | The docs are still true: the README and the plan's status | Their diffs, read against the change |
| N5 | It wasn't called shipped without a review of what changed since the last ship tag | The run's output; the report; the tags |
| N6 | The change is proven and committed the way the first build's commits were: a Conventional Commit subject, a test for the new behavior, the proof in the body | The commit |

## Not on this list

Agreed rules that can't be seen in a built project, or have no occasion to show in these two briefs:

- One agent by default, and how work is split when it is split. The slice has no builder agents.
- A builder's brief stating the goal and not the steps. The same reason.
- Proof by screenshot. Neither brief has a user interface.
- A cut list. Neither brief has a hard limit, so P8 scores its absence.
- A second project of a kind earning that kind its own defaults.
- Each skill working alone on an existing project. The staged run and the change runs show it, and their result files say so.
