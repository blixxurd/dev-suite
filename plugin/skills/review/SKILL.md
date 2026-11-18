---
name: review
description: Gets everything changed since the last ship reviewed by an agent that did not write it, then fixes or decides each finding. Use before shipping, or whenever an independent read of recent work is wanted.
---

# Review

Have the work read by someone who didn't write it, and deal with what they find.

Before starting, read `GAMEPLAN.md`, `docs/decisions.md` and the commits since the last ship. *Why: a review may be the first thing a session does, and one already under way has left its fixes in the history and its declined findings in the log.*

## Done means

- **An independent review of everything since the last ship.** Start the `dev:reviewer` agent on the range from the last `ship-N` tag to `HEAD`, or on the whole history when nothing has shipped. Give it the range and nothing about what you think of the work. *Why: an author rereads what they meant to write, and a reviewer handed the author's view tends to return it.*
- **Every finding is fixed or decided.** Before the first fix, list the findings under Next in the plan's Status and commit that. *Why: a session that stops part-way would otherwise take the open findings with it.* A fix is its own commit, through the gate, quoting the finding. A finding you decide against gets an entry in `docs/decisions.md` saying why.
- **One re-review,** of the fixes only and with the first findings in hand, if anything was fixed. Whatever is still disputed after it, you decide and log. There is no third round; a read of a commit that `ship`'s own checks made is not one. *Why: a review without a bound never ends.*
- **End by saying who reviewed (the agent and its model) and which commits, and by listing each finding, where it was, and what happened to it.** `ship` puts this in the report.

If no agent can be started here, read `${CLAUDE_PLUGIN_ROOT}/agents/reviewer.md`, do the review yourself in its terms, and say in the list that the review was not independent.
