---
name: plan
description: Turns a brief into a gameplan (GAMEPLAN.md) for a software project, stops for the driver's one approval, then runs the first build through to ship. Use to start a new project from a brief, or when handed a new brief for an existing one.
argument-hint: <the brief, as text or a file path>
---

# Plan

The brief: $ARGUMENTS

Turn it into a plan the driver can approve once, complete enough that the build then runs to the end without them. The driver is whoever handed over the brief, a person or another agent. Given no brief, use a brief file in the folder if there is one, and otherwise ask for it.

## When the driver answers

This skill ends its turn by asking for approval, so the next message is the answer.

- **An approval.** If it comes with changes, make them first. Record it in the plan, in the status line at the top and under Approval: who, the date, their words, and that it covers the build through to ship, or the limit they set ("stop after the skeleton"). The approval settles every reading the plan marked "to confirm" that it doesn't change, and the record says so. *Why: the driver saw them before approving, and asking again at ship repeats the question.* Commit what planning wrote (a `docs:` commit, starting a repo on `main` if the folder has none), so the approved plan is in history before any code. Then start `dev:scaffold` with the Skill tool. Each skill starts the next from there, so the build runs through to ship without stopping again.
- **Anything else.** Answer it, change the plan if it calls for that, and ask again. Nothing is built before an approval.

## Done means

- `docs/brief.md` holds the brief word for word. A brief handed over as a file inside the project folder is moved there, so there is one copy. *Why: the review and the report are checked against what was asked, and a paraphrase loses it.*
- `GAMEPLAN.md` is filled in from `${CLAUDE_SKILL_DIR}/gameplan-template.md`. The template's comments say what each section needs and why.
- The turn ends with a short message to the driver: what will be built, each assumption marked "to confirm", anything planned that the brief does not ask for, and whatever approving also agrees to beyond code in this folder (a runtime to install, a credential, a large download, anything outward-facing). Then it asks for the approval. *Why: this is the one stop, so whatever would stop the build later is settled here.*

## Before writing

Look for `GAMEPLAN.md` in the folder.

- **None:** a new project.
- **A draft:** carry on from it.
- **An approved plan:** if the brief is one change that fits in a commit, make it as `${CLAUDE_PLUGIN_ROOT}/skills/build/running-a-build.md` says under "A change the driver asks for", and write no plan. Otherwise the brief is a change to an existing project. Read `docs/decisions.md`, add the brief to `docs/brief.md` under today's date, and revise the plan in place, with the Status saying which steps wait for approval. On approval, start `dev:build` in place of `dev:scaffold`. *Why: a project has one plan, and git keeps its history.*

## How to plan

- **Ask the driver nothing.** Where the brief is open, take the reading that is easiest to undo and write it down as an assumption. *Why: a question is a stop, and the approval settles every assumption at once.*
- **Look first, and write down what you saw.** Probe the real data, API or tool and check which runtimes this machine has, then record in the plan when you looked and what it showed, the surprises above all. Keep a sample inside the project for the build to cut its fixtures from. *Why: a plan made from memory of how something behaves is a guess, and a finding that is only in the conversation is lost to the build's next session.*
- **Start from the defaults for the kind of project.** Read `${CLAUDE_SKILL_DIR}/service-defaults.md` before choosing anything. It lists the principles every project keeps, and says what to do when the project is not a long-running service.
