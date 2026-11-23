---
name: design-checklist
description: Yes/no design questions for the defects reviewers repeatedly find in Tyler's code (trust boundaries, money, unbounded work, silent failure, pagination, concurrency, parsers, cross-repo versions, duplication, tests that cannot fail). Load before writing or changing a CLI companion route, console data path, plugin command or SDK feature, when briefing an implementation agent, and give it to the /akka-pr-review reviewer.
---

# Design checklist

These questions come from about 450 blocker and should-fix findings on Tyler's pull requests between October
and November 2026. Every question below answered "no" was found by a reviewer at least several times.

Answer each question that applies before writing the code, and again before the review. A "no" is fixed, or
written into the PR description as a known limit with its reason.

## Trust boundaries

- Is every path from input joined, then confined to its root after symlinks are resolved?
- Is every URL fetched on a user's behalf checked against an address policy, with credentials dropped on
  redirect?
- Does every route, relay entry or tool admit only the reads and writes a page or command actually makes?
- Is identity taken from something the run cannot edit, never from a file in the project, such as `pom.xml`?
- Is stored data free of prompts, secrets and credentials from connection URLs, unless storing them is the point?

## Money

- Is an unknown amount shown as no value, never as 0?
- Is a sum that is missing some parts marked as a floor, naming what is missing?
- Is a usage class with no rate (cache read, cache write, reasoning) left unpriced, as Optimize's Statements do?
- Is past traffic priced at the rate in force when it happened?
- Does the currency come from the data?

## Unbounded work

- Does every list have a bound on rows, bytes and time, and does the answer say when the bound cut it?
- Is there one time limit per page, never one per read inside it?
- Is a cache sized for the largest read it serves?
- Is there one read for a page, rather than one per row? Where there is one per row, is it capped and stated?

## Errors

- Does one bad item get skipped and reported, while the rest is answered?
- Does a failure read as a failure, never as "not configured", "0", "empty" or "healthy"?
- Does an unreachable dependency answer 503 with the reason? A 404 means only "no such thing".

## Pagination and order

- Is the cursor a keyset (sort key plus id), so a source dropping out, or a row arriving, neither skips nor
  repeats rows?
- Is the output deterministic: no map iteration order, and a full sort with a tiebreak?

## Concurrency and state

- Is shared state in tests and fakes guarded, and is a package variable never overwritten by a test?
- Is no lock held across I/O?
- Do records written by several branches merge in git (one file per record, never one appended file)?
- Does every run that opens get closed, and does an approval end when its subject is re-run?

## Parsing

- Is there a real parser or library for this format (YAML, HOCON, JSON, Java)? A regex or line splice is for a
  format with none.
- Where hand parsing remains: does it survive no trailing newline, comments, strings and char literals that
  contain delimiters, text blocks, overloads, and CRLF?

## Versions across repos

- Does the released CLI, plugin, Optimize or SDK already have each flag, route, field or template this
  assumes?
- Where it needs an unreleased one, does the PR name the PR it depends on and the release order?
- Are reads of another service's API taken from its current source, never copied from an older version?

## Reuse and scope

- Is there an existing helper, component or library for this? Search before writing.
- Is nothing exported for a later PR, and no dead code left behind?
- Is the PR under about 2,000 non-test lines, with one purpose? If not, split it before opening.
- Are the design and scope decisions written in the PR description?

## Tests

- Does each guard have a test that fails when the guard is deleted?
- Was no assertion loosened to make a test pass?
- Does it work on macOS and Linux as well as Windows: `python3`, `mvnw`, path separators, case-sensitive file
  systems, global git config?
- Is it backward compatible for people on the released version?
