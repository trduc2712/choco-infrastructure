---
name: adr
description: Write or review an Architecture Decision Record in docs/adr. Use when a system-wide or hard-to-reverse decision is settled (provider, hosting, storage design, environments, infrastructure tooling, deploy process), when an earlier decision is replaced, or when reviewing an ADR draft.
---

# Architecture Decision Records

An ADR records one settled decision: the problem, the options weighed, the choice and its cost. It is written once and never rewritten; a changed decision gets a new ADR.

This repository holds the decisions about the Choco platform as a whole and its infrastructure. Decisions about the code inside an application belong in that application's own repository.

## Workflow

1. Read every ADR in `docs/adr/` to find the next number and any decision the new one touches or contradicts. When the decision involves an application, ask the user whether any of its ADRs touch it.
2. Ask the user for the context, the options they considered and the option they chose. The decision is the user's; never invent options, reasons or a choice.
3. Write the draft and wait for the user's approval of its content.
4. When it replaces an earlier ADR, change only that ADR's Status line (rule 17).
5. Check that every relative link in the ADR resolves.

## Scope

1. Write an ADR for a decision that shapes the whole platform or is costly to reverse: external providers, hosting and regions, storage design, environments, secrets handling, infrastructure tooling, deploy processes.
2. Do not write one for a decision that one pull request can undo, or for how-to or operational detail; that goes in `docs/*.md`, and the ADR links to it.
3. Do not write one here for a decision internal to an application's code, such as its layers, libraries or data access; suggest an ADR in that application's repository instead.
4. Suggest an ADR when a conversation settles such a decision, but write it only when the user asks.

## File and Title

5. Name the file `NNNN-<verb-phrase>.md`: the next free four-digit number and a lowercase, hyphenated phrase that states the decision (`0002-host-the-api-on-render.md`). Numbers are this repository's own, independent of other repositories.
6. Title it `# N. <Decision in Title Case>`, with the number without leading zeros. The title states the same decision as the file name and may use fuller words.
7. Below the title, write `Date: YYYY-MM-DD`, the date the decision was accepted.

## Sections

8. Use exactly these sections, in this order: `## Status`, `## Context`, `## Considered Options`, `## Decision`, `## Consequences`.
9. Context states the problem, the forces and the constraints, and names no solution.
10. Considered Options lists at least two real options as bullets, worded neutrally and at the same level of detail, including the one that was chosen.
11. Decision opens with one sentence, `Choco uses X.`, then bullets for the rules the decision implies, then one paragraph that says why each rejected option lost.
12. Consequences has two lists, `Easier:` and `Harder:`. Harder lists the real costs, each one concrete; it is never empty.

## Style

13. Write plain English sentences in present tense. Name no Terraform resources, variables, modules or files, except a doc the reader is pointed to; an ADR outlives the code.
14. When the decision rests on a provider's limits or prices, state them with the date they were checked and link the provider's page; free tiers change without notice.
15. Refer to an ADR in another repository by repository and number, such as "<repository> ADR 2". Wrap lines at about 78 characters, as the existing ADRs do.

## Status and Change

16. Status is one of `Proposed`, `Accepted` or `Superseded by [N](NNNN-file.md)`. A new ADR is `Accepted` once the user has approved its content.
17. Never edit the content of an accepted ADR. To change a decision, write a new ADR whose Context names the one it replaces, and change only the old ADR's Status to `Superseded by` the new one.
