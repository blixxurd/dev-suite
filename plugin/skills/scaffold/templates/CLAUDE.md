# <Project name>

<!-- This file is for agents and is the same shape in every project. Fill it in, delete the comments, and leave out any section with nothing to say. It holds what an agent arriving cold cannot get from the code. How to run things belongs in the README, decisions in the log, and repeatable procedures in project skills. -->

<One paragraph: what this is, what kind of project, and the constraints that cannot be seen in the code.>

## Read first

- `GAMEPLAN.md`: the plan. Its Status section says what is done, what is next and what is blocked.
- `docs/decisions.md`: calls made since the plan was approved.
- `docs/brief.md`: what was asked for, word for word.

## Commands

`make help` lists them. `make setup` once per clone switches on the commit gate. `make check` is what the gate runs.

## Contracts

<!-- One line per interface: where its contract lives. An agent reading one folder cannot see this. -->

## Every change

<!-- Kept word for word. It is the floor for changes made without the plugin. -->

1. A finished change ends in a commit through the gate, and the gate stays green. Fix what it flags; never change, skip or delete a check to get past it.
2. A contract changes before the code on either side of it.
3. A call someone could reasonably have made differently gets an entry in `docs/decisions.md`.
4. Docs stay true. When behavior changes, so do the README and the plan's Status.
5. Nothing is called shipped without a review, by an agent that did not write it, of everything changed since the last `ship-N` tag.

## Never / ask first

<!-- This project's hazards: what is costly or cannot be undone. -->

## Rules the tools don't check

<!-- First one line naming the tools that enforce the mechanical rules, so nobody restates them here. Then only judgment and naming rules that are specific to this project. General rules stay in the plugin. -->

General rules for building are in the `dev` plugin: `/dev:standards`.

Add a line to this file only when an agent got something wrong without it.
