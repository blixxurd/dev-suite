# Scoring a trial run

What a scorer is handed. A finished run is scored against [the checklist](checklist.md) by an agent that did not write the suite and is told nothing about what its author expects to find. The author then reads the scores, runs a sample of the evidence again and writes the rest of the result.

Your prompt names the run, the checklist groups to score, a scratch folder, and the folder your evidence goes in.

## The job

Find out what is true of a project that another session built, and score it a line at a time. A "no" with its evidence is worth as much as a "yes". Score what the run left and not what it says about itself: where its report or a commit body claims something, run it or open it.

Your scores have to be your own. In this repo read only this file, the checklist, the two briefs and `plugin/`. Skip the reading list in the repo's `CLAUDE.md`, which is for agents working on the suite, and leave `trials/results/` unread, along with any `check-*` or `score-*` folder in a run's `.out` folder. *Why: those hold other looks at this run or at one like it, and a scorer who has read them hands them back.*

## What the run left

- **The project:** `~/Projects/dev-suite-trials/<run>/`, a git repo. The brief it was given is `docs/brief.md`, or `brief.md` in a run without the plugin.
- **The runner's output:** `<run>.out/` beside it. `log.txt` has the start and the end of every call into the run. `N.prompt` is what the driver sent in call N, and `N.json` is what came back: the session's last message (`result`), its turns, cost, models and agents. Its cost and token counts are running totals for the session, so a session continued in a later call counts its earlier calls again, and its turn count can cover only the end of the call. `before.txt` is the machine before the run began. `after.txt` is the report on what the run did beyond its folder. It matches too much on purpose, so judge each line it flags.
- **The transcripts:** under `~/.claude/projects/`, in the folder named after the project's path with each slash turned into a dash. A session is `<session id>.jsonl`, and an agent it started is `<session id>/subagents/agent-*.jsonl` with a `.meta.json` beside it. They are long, so query them with `jq` and never read one whole. A tool call is a `tool_use` item in `message.content[]` of an `assistant` line, and its result is a `tool_result` item in a `user` line.
- **For a run with the plugin:** `plugin/` in this repo holds the templates and the formats that the run's files answer to.

## Rules for working on this machine

The machine is the driver's own. Treat its disk as scarce.

- **Change nothing the run left:** its folder, its transcripts, what it left in Docker, and its `.out` folder apart from your evidence. Work in a clone of its repo inside your scratch folder, and delete the clone when you finish. *Why: the run is the evidence, and whoever looks next has to find what the run left.*
- **Load `<run>.out/env.sh`** in every shell call that runs the project's commands, and point `TMPDIR` and any cache a tool would keep in the home folder at your scratch folder. *Why: the file sends package caches to the run's own cache folder, which is deleted once the run is scored.*
- **Install nothing system-wide, and fetch as little as you can.** What the run fetched is in its cache, so building it again should need nothing new. Where a package manager can be told to stay offline without breaking the line you are scoring (`GOPROXY=off`, `npm_config_offline=true`), tell it. Looking something up is fine: a registry's list of versions, a release list, a vulnerability database, the public source the brief names. Anything else you fetch goes in the run's cache or your scratch folder, and your evidence says what it was and how big.
- **Stop only what you started,** a process by the ID it got when it started, and anything in Docker by a name you chose. Never stop anything by name or pattern (`pkill`, `killall`). *Why: a name or a pattern also matches the driver's own work.*
- **In Docker, name everything you start** so that it can't be taken for the run's or the driver's. List images, containers and volumes before you begin and when you end, and remove what you made. If a build moves an image tag that was already there, tag the old image first and move the tag back afterwards. Put a time limit on every Docker command, because Docker can hang. Where there is no `timeout` command (macOS has none), use `perl -e 'alarm shift; exec @ARGV' <seconds> <command>`.
- **If a line can't be scored inside these rules,** score it "not checked" and say what it would have taken. Don't work around a rule.

## Scores

The checklist's own "Scoring" section says how a line is scored. Evidence is something that can be run or opened again: the exact command with the lines of its output that matter, a file and line, or a commit. Add "not checked", with the reason, only for a line you could not score.

## Two things every run gets beyond the checklist

Neither is scored, and your prompt says which of them are yours.

- **Do the tests notice?** In the code that carries the brief's requirements, make about thirty single changes, one at a time, each to behavior a user could see: a comparison turned round, a boundary moved by one, a condition dropped, a default changed, an error swallowed. Spread them across the requirements. Run the project's tests after each and put the code back. Report how many the tests caught, and every one they missed with its file and line.
- **What the run's own review missed.** Keep a list of whatever you find that is wrong, or that breaks a rule on the checklist, and that the run's own review doesn't mention: where it is, what it is and how you know. The review's findings are in its agent's transcript and in the report. *Why: the result measures the run's review against this list.*

## What you hand back

`evidence.md` in the folder your prompt names, with:

1. One table for each checklist group you scored, in the checklist's order and under the group's heading (`### W. …`), with the columns `ID`, `Score` and `Evidence`.
2. "Do the tests notice?", if that one was yours.
3. "Found, and not in the run's review", if that one was yours.
4. "Not on the checklist": anything else worth knowing about the run.
5. "This machine": the listings before and after, what you made and removed, and anything you left.

Long output goes in `logs/` beside it, and the evidence cites the file. Keep the character `|` out of table cells, because it ends the cell.

Reply in at most thirty lines: the number of each score in each group, every line that isn't a yes, what you couldn't check, and what you left on the machine.
