---
name: build
description: Works through the build order of a project's gameplan on its own, one proven commit per step. Use once a project made with the dev plugin has its skeleton, to build the remaining steps, to carry on a build that was interrupted, or to build an approved change.
argument-hint: "[what the driver said, if anything]"
---

# Build

Work through the plan's build order, from the first step the Status doesn't show as done to the last one approved, without stopping to ask.

The driver's words, if any: $ARGUMENTS

Before starting, load `dev:standards` and read `GAMEPLAN.md`, `docs/decisions.md`, the project's `CLAUDE.md` and `${CLAUDE_SKILL_DIR}/running-a-build.md`. *Why: a build may be picked up by a session with no memory of the last one, and these are where the last one left what it knew.*

How far this build may go is set by the plan's Approval and the driver's words above, read as `running-a-build.md` says under Approval. If no step is left, go straight to handing on below, unless the Status says everything built has shipped: then make the change the driver asked for, if any, as `running-a-build.md` says under "A change the driver asks for", or say so and stop. *Why: a session can end between the last step and the ship, and the approval still covers the ship.*

## Done means

- **Every approved step is built,** or one is reported blocked. A step is built when everything in its "done when" is true.
- **One commit per step** (a refactor still gets its own, as the standards say), in the plan's order, its body showing the "done when" holding. *Why: a history that follows the plan can be checked against it and undone a step at a time.*
- **Handed on.** If the approval covers the build through to ship and nothing is blocked, start `dev:ship` with the Skill tool. Otherwise end by saying what was built and that it has not shipped.
