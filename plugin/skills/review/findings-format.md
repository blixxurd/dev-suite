# Findings

What a review hands back: a numbered list of findings, or the two words "Nothing found", which is a valid result. The lead fixes or decides every finding and copies the list into the report, so each one has to stand on its own.

One finding is one line with three parts:

1. **Where:** `path/to/file:line`. For something that is missing, the file it belongs in.
2. **What:** the rule it breaks, named so it can be looked up (a numbered rule in the standards, a line of the project's CLAUDE.md, a requirement in the brief), or a scenario that fails: the input or state, and what goes wrong.
3. **Fix:** the smallest change that would settle it.

Two examples, one of each kind:

> 1. `src/orders/totals.ts:14`. Standards 1, one home: the tax rate `0.2` is written here and again in `src/invoices/render.ts:30`. Fix: export it once from `totals.ts` and read it in the renderer.
> 2. `src/orders/import.ts:52`. A file that ends in a blank line fails: its last row is read as an order with no id, and the import stops with a null error instead of the validation error every other bad row gets. Fix: skip empty rows before validating.

Something that can't be given a where and a what is an impression, not a finding, and is left out. So is anything a tool in the gate already checks.

In a re-review, each earlier finding is answered first, by its number, with **settled** or **still open** and why. New findings may only be about what the fixes changed.
