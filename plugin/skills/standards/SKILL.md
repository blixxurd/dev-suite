---
name: standards
description: The ten rules for writing code in a project built with the dev plugin, each with its reason. Load before writing, changing or reviewing code in one.
---

# Standards

This is the whole list. Whatever a tool can check (types, unit size, dead code, formatting, commit subjects) is enforced by the project's gate and left off. A project's own rules are in its `CLAUDE.md`.

1. **One home for every fact.** A value, a shape or a rule lives in one place and everything else reads it from there. Give a literal that means something a name. Similar code may appear twice; extract it the third time. *Why: two homes drift apart, and an abstraction guessed too early is harder to undo than a repeat.*
2. **Pure core, I/O at the edges.** Logic takes values and returns values. Network, disk, clock and environment are touched only in the outer layer. *Why: the core can be tested without mocks and reused from another entry point.*
3. **Validate at the boundary, fail on one path.** Check input once, where it enters (a request, a file, the environment, someone else's API), and pass typed values inward. Every failure leaves through the same error path. *Why: inner code can trust what it is given, and every error looks the same to callers and in the logs.*
4. **Contract first.** Change the contract file before the code on either side of an interface. *Why: the contract is the one home for an interface's shapes, and code written first turns it into a description of whatever got built.*
5. **Tests pin behavior someone relies on.** Test through the public surface, with data cut from the real thing. For a bug, write the failing test first. *Why: these tests survive refactors, and a test that failed before the fix proves the fix.*
6. **Prove every change with proof that fits it.** Identical output for a refactor, a test that used to fail for new behavior, a screenshot for UI. The evidence goes in the commit body, and a refactor gets its own commit. *Why: "should work" can't be checked, and a mixed commit hides which change did what.*
7. **Build the structure, leave out the extras.** Layers, boundaries and single homes go in from the start. Features, options and endpoints nobody asked for stay out. *Why: structure is costly to add later. Extras are cheap to add later and costly to carry until then.*
8. **Cut scope, never compress code.** When something won't fit a limit, do less or split it by concern. Don't shorten names, join lines or drop checks to fit. *Why: the limits exist for readability, and compressed code defeats them.*
9. **Leave the gate alone.** Fix what it flags. Never change, delete or skip a check, a lint rule or a test to get past a failure. The one exception is a single-line suppression with a comment saying why, logged in the decision log. *Why: a gate that bends stops telling you anything.*
10. **Write down the calls.** A choice someone could reasonably have made differently gets a dated entry in the decision log. A new dependency gets its reason in the plan's stack table. Comments say why, not what. *Why: the next agent starts with no memory of this one.*
