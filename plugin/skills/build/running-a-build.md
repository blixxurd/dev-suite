# Running a build on your own

After the plan is approved, the build runs to the end without the driver. These are the rules for that, shared by `scaffold`, `build` and `ship`.

## Approval

The plan's Approval says how far the driver has agreed the work may go: which steps, and whether a ship. What the driver says to this session can take that further or stop it sooner. When it does, record their words under Approval (the date, the words, what they cover) and commit that before anything else. If neither covers what this session is about to do, stop and say so. *Why: the approval is what allows the work, and the next session reads the plan, not this conversation.* A change the driver asks for in so many words is the exception, as the next section says.

## A change the driver asks for

Once the plan's build is done, a change the driver asks for in so many words needs no plan step and no record of its approval: their words are both. Make it in one commit, with any refactor it needs in a commit of its own before it. Change the contract first if it changes an interface, and prove new behavior with a test that fails before the change. The commit body quotes the driver's words and gives the proof, and the same commit adds a line to the plan's Status saying what changed. Leave the plan's other sections as they are: once the first build has shipped they are history, and the README, the contracts and the tests say what the program does now. A reading the words leave open gets a decision entry, as under Changing course; one the words settle needs none. *Why: the words are already the approval and the spec, a plan step for a single commit is bookkeeping that no later session reads, and a fact kept in the plan as well as in the README and the contracts has two homes that drift.* A request that takes several steps, or changes what the brief asks for, is a new brief for `dev:plan`.

## Changing course

The plan was approved once. What may change after that depends on the kind of change.

1. **An engineering choice inside the approved requirements** (a library, a structure, the order of steps). Decide, add an entry to `docs/decisions.md` marked settled, and update the plan wherever it now reads wrong.
2. **Product behavior the brief leaves open** (what a filter does at its edge, what an error says). Take the reading that is easiest to undo, add an entry marked "to confirm", and keep going. The report collects these for the driver.
3. **Stop and ask** only when a requirement can't be met or would have to be dropped (unless the plan's cut list covers it), when something is irreversible or outward-facing (a push, a publish, a deploy, a message, a deletion outside the project), or when the work needs a credential, a runtime installed on the machine or a large download that the approval didn't cover.

*Why: the driver approved once so that the build would not need them again, and a stop for anything smaller wastes that. The three stops are for what the driver can't undo afterwards, or what only they can give.*

## Stuck

After three failed attempts at the same failure, stop working on that step. Write down what was tried and what each attempt showed, mark the step blocked in the plan's Status, and end by reporting it. *Why: a fourth attempt in the same direction costs more than a fresh look, and attempts made to get past a check tend to bend it.*

## Status

The plan's Status says what is done, what is next and what is blocked. It is brought up to date in the same commit as the work it describes. *Why: it is how the next session, with no memory of this one, knows where to carry on.*

## The driver's machine

Stop only what this build started. A process is stopped by the ID it was given when it started, never by name or pattern (`pkill`, `killall`). Anything else that runs is stopped by a name this build chose for it. *Why: the build shares the machine with the driver's own work, and a name or a pattern also matches theirs.*

Scratch work goes in a folder this session made for it. Before ending, remove what this session made that nothing needs any more: scratch folders, and the images, volumes and anything else its checks built or started. What the project keeps on purpose, such as its data, stays. Removing what this session made is not a deletion that needs the driver. *Why: the driver doesn't know these exist, so nobody else will remove them.*
