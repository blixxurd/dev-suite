# dev suite

A Claude Code plugin named `dev`: skills, templates and a few shell scripts that plan, build and ship software projects the way a good developer builds them. Nothing here runs as a process. The plugin is the `plugin/` folder and only that ships; `.claude-plugin/marketplace.json` is how people install it, and the rest of the repo is for working on it. The skill files are loaded by agents in every project the plugin builds, so each sentence added to one is paid for in all of those sessions.

## Read first

- `README.md`: what the plugin does and how it is installed, written for people.
- If this clone has them: `GAMEPLAN.md`, whose Status says what is done, next and blocked; `docs/decisions.md`, the calls made so far; and `docs/brief.md`, what the plugin was asked to be, whose section 4 lists what was declined (don't propose those again). They are the maintainer's planning files. Git ignores them, so a public clone works without them.

## Commands

`make help` lists them. `make setup` once per clone switches on the commit gate. `make check` is what the gate runs.

## Contracts

The interfaces here are the files that skills hand to each other and to the driver.

- `plugin/skills/plan/gameplan-template.md`: the gameplan. Other skills find its sections by heading.
- `plugin/skills/scaffold/templates/`: what every built project is given, the two git hooks among them. `.githooks/` here links to those same hook files.
- `plugin/skills/review/findings-format.md`: what a review hands back.
- `plugin/skills/ship/report-template.md`: the report.
- `trials/checklist.md`: what a trial run is scored against.

## Every change

1. A finished change ends in a commit through the gate, and the gate stays green. Fix what it flags; never change, skip or delete a check to get past it.
2. A contract changes before the code on either side of it.
3. A call someone could reasonably have made differently is written down: in `docs/decisions.md` where this clone has it, otherwise in the commit body.
4. Docs stay true. When behavior changes, so does the README, and the plan's Status where there is one.
5. A release comes after a review, by an agent that did not write it, of everything changed since the last `v*` tag. It raises `version` in `plugin/.claude-plugin/plugin.json` and is tagged `v<version>`, because installed copies update only when the version moves.

## Never / ask first

- `origin` is the public GitHub repo, so whatever is pushed is published. Push `main`, and any new `v*` tag, once a piece of work is done and reported to the maintainer. Never force-push, and never add another remote. Never commit the planning files, or anything that names a person, an email address or a machine.
- A trial run starts a headless Claude session with permission prompts off and costs a small build in tokens. Ask before starting one.
- Never fit a skill to a trial brief: no skill may name earthquakes, link checking or anything else from `trials/`. A skill tuned to the test stops the test from measuring anything.

## Rules the tools don't check

`make check` enforces the plugin's structure, the size of skill files, names, links, plugin paths, shell syntax, the hooks' behavior, where service words may appear, and how a trial run is launched and reported on.

- A skill states the goal, the inputs and what done means, not the steps. Every rule in it carries its reason.
- Each rule has one home: a tool in the built project, the reviewer, or `standards`. Before adding a sentence to a skill, check that none of those already says it and that plain Claude Code doesn't already do it unasked. A trial run without the plugin (`trials/run.sh` without `-p`) shows what it does.
- What fits only one kind of project goes in that kind's defaults file and reaches the other skills through a project's plan.

General rules for building are in the plugin itself: `plugin/skills/standards/SKILL.md`.

Add a line to this file only when an agent got something wrong without it.
