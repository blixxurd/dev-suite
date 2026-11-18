---
name: ship
description: Ships the current state of a project built with the dev plugin. An independent review, a prune, the slow checks from a fresh clone, a written report and a local ship-N tag. Use when a build or a later change is finished.
argument-hint: "[what the driver said, if anything]"
---

# Ship

Make the work something that can be handed over: reviewed, pruned, proven from a fresh clone, reported and tagged. Shipping means a report and a tag in the local repo. Pushing, publishing and deploying are outward-facing and stay the driver's call.

The driver's words, if any: $ARGUMENTS

Before starting, load `dev:standards` and read `GAMEPLAN.md`, `docs/decisions.md`, the project's `CLAUDE.md` and `${CLAUDE_PLUGIN_ROOT}/skills/build/running-a-build.md`. *Why: a ship may be the first thing a session does, and its fixes and its prune are changes like any other.*

A ship needs the driver's say, read as `running-a-build.md` says under Approval. Starting this skill themselves is the driver asking for a ship. If a step of the build order is neither done nor marked blocked, say which and stop.

## Done means

1. **Pruned.** Nothing is left that no requirement and no agent needs: scratch files, unused code and dependencies, docs describing what is no longer there. The gameplan, the brief, the decision log and `CLAUDE.md` stay. What is removed goes in a commit of its own.
2. **Reviewed.** Start `dev:review` with the Skill tool and finish it before anything below. *Why: a prune changes code too, and the tag must cover nothing the review didn't read.*
3. **The plan's ship checklist passes from a fresh clone.** Clone the repo into a scratch folder and run the checklist there. Keep each check's output for the report. A known high-severity issue found by the dependency audit is fixed if a fix exists, and listed in the report if not. A commit this step makes is read by the `dev:reviewer` agent, like a re-review, before the report.
4. **Every commit subject since the last ship passes** `.githooks/commit-msg`. A bad one is listed in the report and left as it is, because rewriting history can't be undone.
5. **`REPORT.md`** is written from `${CLAUDE_SKILL_DIR}/report-template.md`, and every proof it names was run for this ship. The same commit makes the plan say shipped, in its status line and its Status, with the checklist ticked.
6. **Tagged.** That commit gets an annotated tag, `ship-N`, one more than the last.
