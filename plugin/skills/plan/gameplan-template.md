# <Project name>: gameplan

**Status: draft, written <YYYY-MM-DD>, waiting for approval.**

<Two or three sentences: what is being built, and for whom.>

This file is the plan and its history, not the rules. The rules are in the tools behind `make check` and in `CLAUDE.md`. The brief is in `docs/brief.md`, word for word. Calls made after approval go in `docs/decisions.md`. Once the first build ships, everything here but the Status is history: what the program does now is in the README, the contracts and the tests.

<!-- Using this template: fill every section, then delete every comment, this one included. Write for two readers who were not there: the person approving, and the agent who picks the build up later with no memory of this session. Keep the headings as they are, because the other skills find sections by name. Apart from the cut list, a section with nothing to say keeps its heading and says so in a line. -->

## 1. What the brief asks for

<!-- One row per requirement, in the brief's own words. Proof is what will show it works: a test by name, a command and its output, a screenshot. The report at ship is built from this table, so a requirement missing here is one nobody proves. -->

| # | Asked for | How it is satisfied | Proof |
|---|---|---|---|

Not wanted: <what the brief rules out>

## 2. Assumptions

<!-- Everything taken as given without asking, so it is settled at the approval instead of stopping the build:
- The kind of project, and the defaults that follow. When no defaults are written for this kind, a table with the equivalent of each written default, or "no equivalent" and why.
- Each reading of something the brief leaves open, marked "to confirm" until the approval settles it. Take the reading that is easiest to undo.
- A plain statement if this is not a long-running service, or if it needs storage that outlives the process.
- Any gap between a runtime this plan pins and what the machine has. -->

## 3. Decisions

<!-- Choices someone could reasonably have made differently. "Why" includes what was ruled out, so the next agent doesn't reopen a settled question or undo a choice without knowing what it was for. Anything to be built that the brief does not ask for and the defaults do not bring (an option, an endpoint, a field) is such a choice: it gets a row here saying what needs it, or it is left out. -->

| Decision | Choice | Why |
|---|---|---|

## 4. Checked against the real thing

<!-- What was probed before planning (the data, the API, the installed runtimes), on what date, and what it showed, above all what a careless build would trip on. Name the fixtures that will be cut from it. A plan written from memory of how something behaves is a guess. -->

## 5. Design

<!-- The parts, their boundaries, and how data flows between them. Then one row for every interface, between parts or to the outside. A contract is the single home for its interface's shapes: code is generated from it or checked against it, and people read a view rendered from it. Default formats: OpenAPI for an HTTP API; the command definition plus JSON Schema for `--json` output for a command-line tool; JSON Schema for files, config and events; the typed exported interface for a library. Another format is a decision, with its reason. -->

| Interface | Contract: format and file | How code is checked against it | How the readable view is made |
|---|---|---|---|

## 6. Stack and versions

<!-- The newest LTS runtime that every chosen dependency supports, pinned. Versions are looked up in the registry today, not recalled. Every dependency needs a reason, and "it is the usual choice" is not one. -->

| What | Version | Checked on | Why it is needed |
|---|---|---|---|

<!-- Which tool enforces each mechanical rule in this stack. Scaffold proves every row by planting a violation. A rule this stack cannot enforce says so here and goes to the reviewer. -->

| Mechanical rule | Enforced by |
|---|---|
| Strict types | |
| Small units (the limits for this kind of project) | |
| No dead code, no unused exports | |
| No suppression without a reason on the line, no TODO left behind | |
| Lint and formatting | |
| Code matches its contracts | |
| Commit subject format | `.githooks/commit-msg` |

## 7. Build order

<!-- Steps small enough to prove one at a time, each serving a row of section 1. Step 1 is the walking skeleton, and its "done when" is the whole skeleton checklist for this kind of project, because `scaffold` builds exactly that step and the gate behind it. The fixtures cut from real data and the contracts come next, before any feature. "Done when" is something that can be checked. -->

| # | Step | Done when |
|---|---|---|

## 8. Risks

<!-- What could make this plan wrong or the build fail, and what is done about each now, while it is cheap. -->

| Risk | Mitigation |
|---|---|

## 9. Cut list

<!-- Only when the brief has a hard limit (a deadline, a cost ceiling, a size cap): what is cut, in order, if the work will not fit. Approving the plan approves these cuts. With no hard limit, delete this section and close up the numbers. -->

## 10. Ship checklist

<!-- What must pass before this is called shipped, for this kind of project. Always on the list: a review of everything changed since the last ship, a prune, `make check` from a fresh clone, the artifact built from that clone, a dependency audit, the report, and a `ship-N` tag. -->

- [ ] <check>

## 11. Status

<!-- Kept current all through the build. It is how the next session knows where to pick up. -->

- **Done:**
- **Next:**
- **Blocked:**
- **Approval:** not given yet.
