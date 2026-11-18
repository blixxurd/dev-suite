---
name: scaffold
description: Turns an approved gameplan into a walking skeleton with a proven commit gate, and commits it. Use once, after a plan made with the dev plugin has been approved and before any feature is built.
---

# Scaffold

Build step 1 of the plan's build order: the walking skeleton, and the commit gate every later commit goes through. Nothing a later step delivers is built here. *Why: the gate has to exist before the code it is meant to check.*

Before starting, load `dev:standards` and read `GAMEPLAN.md`, `docs/brief.md` and `${CLAUDE_PLUGIN_ROOT}/skills/build/running-a-build.md`. If the plan's Status records no approval, stop and say so: the approval is what allows building. If step 1 is already done, go straight to handing on below. *Why: a session can end right after the skeleton, and the approval still covers what follows.* If the folder is not a git repo, start one on `main` and commit the brief and the plan first.

## Done means

- **The files every project has.** From `${CLAUDE_SKILL_DIR}/templates/`: `CLAUDE.md` and `Makefile` at the root and `decisions.md` in `docs/`, each filled in as its comments say; `pre-commit` and `commit-msg` in `.githooks/`, unchanged and still executable. *Why: the hooks are tested where the plugin is built, and an edited copy is not.* A `README.md` for people: what this is, and how to set it up and run it. A `.gitignore` that covers env files, dependencies and build output.
- **The stack the plan names.** The runtime is pinned where its tools read it, and the manifest and lockfile hold the plan's dependencies at the plan's versions. A dependency the plan doesn't list is a decision.
- **The skeleton.** Everything in step 1's "done when" is true. The layers and boundaries the design names are in place, each contract the skeleton touches is written, and one real test goes through the public surface.
- **The gate.** `make setup` switches on the hooks, and `make check` runs every tool in the plan's mechanical-rules table and the fast tests. Slow checks stay out of it and run at ship.
- **The gate is proven.** For each row of that table, break the rule on purpose in the working tree, run `make check`, see it fail for that reason, and undo it. Try a bad subject with `sh .githooks/commit-msg <file>`. The commit body lists what was planted and what refused it. A rule that no tool here can enforce is not dropped: log it as a decision and say so in the table, so the reviewer checks it. *Why: a gate that has never refused anything may be checking nothing.*
- **One commit** through the gate, with the plan's Status updated in it. No remote, no CI and no hosting config: those are set up later, if the driver wants them.
- **Handed on.** If the plan's Approval covers the build through to ship, start `dev:build` with the Skill tool. Otherwise end by saying the skeleton is in place.
