---
name: akka-pr-review
description: Independent, read-only pre-push review of the current branch. Run before pushing a branch or opening a PR against a repository in the `akka` GitHub organization. Spawns a fresh agent that has not seen how the change was made, so it judges the root cause and the approach on its own. Also use when the user asks for a "pre-push review", "independent review", or "review before I push".
---

# Independent pre-push review (akka org)

The point of this skill is **independence**. The session that wrote the change
cannot review it — it already believes its own approach. So the review runs in a
fresh agent that is given the *problem*, never the *fix*.

## 1. Confirm this is an akka-org repo

```bash
git remote get-url origin
```

If the remote is not under `github.com/akka/` (or `git@github.com:akka/`), say so
and ask whether to run the review anyway. Don't run it silently on the wrong repo.

## 2. Establish the base branch

```bash
git rev-parse --abbrev-ref origin/HEAD    # e.g. origin/main
git branch --show-current
```

Use the resolved base everywhere below in place of `main`. If `origin/HEAD` is
unset, fall back to `main`, then `master`, and state which you used.

## 3. Write the problem statement — the symptom, not the fix

This is the part that must be done carefully. Derive it from the issue, the spec,
or the failing test — **not** from the diff or from what this session did. It
states the symptom and the intended behaviour, and stops there.

If you cannot reconstruct the problem without describing the fix, ask the user for
it rather than guessing. A leaked approach makes the whole review worthless.

End the statement with exactly:

> That is the problem and intent only — work out the cause and judge the solution yourself.

## 4. Run the pre-push checks first

Run `/pre-push` on the branch before launching the reviewer. A reviewer's time on
format, lint, races or a failing suite is time not spent on design.

## 5. Launch the reviewer

Spawn **one** `general-purpose` agent (fresh context — do not use a fork, and do
not summarise the change for it). Its prompt is the block below with `<REPO>`,
`<BASE>`, `<PROBLEM STATEMENT>`, and `<REPORT PATH>` substituted.

`<REPORT PATH>` is `~/.claude/reviews/<repo>-<branch>-review.md`, with `/` in the
branch name replaced by `-`. It lives outside every repo, so the report can never
land on the branch under review.

```
You are doing an INDEPENDENT, read-only code review of work a previous session did
in this `<REPO>` checkout. You have deliberately NOT been told how it was done —
form your own judgment. Do not assume the change is correct, minimal, or that its
approach is the right one.

Do NOT edit code, apply a fix, commit, or switch branches. The ONLY file you may
write is the review report named under "Output" below (it lives outside any repo,
so it never touches the code or the branch). Re-running a build/test to verify is
fine and encouraged.

## The original problem (what it was asked to solve)
<PROBLEM STATEMENT>

## What to do
1. Look at the change on the current branch vs <BASE>:
   `git --no-pager log --oneline <BASE>..HEAD`
   `git --no-pager diff <BASE>...HEAD`
2. Determine the root cause yourself from the code, then judge the change against
   your own understanding — not against any assumed approach.

## Assess
- **Correctness / root cause** — does it fix the real cause, or just silence the
  symptom? Is the change applied in the right place, and complete?
- **Verification** — is there real evidence it works (tests/build run on THIS
  platform)? If practical, re-run the relevant test/build yourself rather than
  trusting the prior run.
- **Test integrity** — fixed by changing production code, NOT by weakening,
  skipping, or retiming a test? If a test/spec was changed, is that justified?
- **Scope** — is every changed file actually part of this task? Flag anything
  unrelated, leftover, vendored, or out of scope, however small.
- **Regression risk** — what else could this affect? Note what's worth running.
- **Quality** — style consistency, logging, naming.
- **Design checklist** — read `~/.claude/skills/design-checklist/SKILL.md` and
  answer each question that applies to this change. Every "no" is a finding.
- **Guard deletion** — for each guard the change adds (a bound, a check, a
  refusal, a lock, a filter), remove it in a throwaway copy (`go test -overlay`,
  a scratch file, or a stash you restore) and run its tests. A test suite that
  still passes without the guard is a [should-fix]: the guard is untested.
- **Other platforms** — does anything assume Windows only, or break on macOS and
  Linux (`python3`, `mvnw`, path separators, case-sensitive file systems)?
- **Released versions** — does it rely on a flag, route, field or template that
  the released CLI, plugin, Optimize or SDK lacks? If so, is the dependency and
  release order stated?
- **PR description** — if a PR exists (`gh pr view --json body`), does its
  description match the diff, name what it depends on, and state the release
  order? A description that claims what the diff does not do is a [should-fix].
- **Hygiene** — no references to private repositories, internal documents,
  customer names, or real email addresses other than examples; no pseudo-version
  pins to unmerged commits; no AI attribution in commits or the description.
- **Size** — count non-test lines changed
  (`git diff --numstat <BASE>...HEAD`, excluding test, testdata and fixture
  files). Over about 2,000 is a [should-fix] that proposes how to split it.

## Output
Write your review as Markdown to **`<REPORT PATH>`** (create the parent directory
first; create/overwrite — outside any repo, so it won't pollute the branch).
Structure:
- **Verdict** on the first line: READY TO PUSH / NEEDS WORK / NEEDS HUMAN DECISION.
- **Findings** — a list, each tagged `[blocker]` / `[should-fix]` / `[nit]`, with
  `file:line` and a one-line rationale.
- **Verification** — what you ran and its result.

Keep it concise — a pre-push sanity review, not a full audit. End your turn by
printing the verdict line to stdout too, so it also lands in the run log.
```

## 6. Report back

Print the verdict line and the report path. Then list the findings, most severe
first. Do not act on them — the user decides what to fix and whether to push.

Never push as part of this skill.

## How this is enforced

The `pre-akka-push` hook denies a `git push` from an akka-org feature branch unless
this skill's report exists for the branch, is newer than the branch tip, and says
`READY TO PUSH`, and unless the `/pre-push` checks report for the branch is newer
than the tip and says `Checks: PASS`. So a report that goes stale behind new commits stops being
sufficient — re-run the skill after amending the branch.

## Re-review after fixes (keep the cycle fast)

When a review returned NEEDS WORK and fixes were committed, the re-review covers
only the commits since the last reviewed tip, not the whole branch: give the
reviewer that commit as its base (`git diff <last-reviewed-tip>...HEAD`), the
previous report's findings, and the same problem statement, and ask it to confirm
each finding is fixed, check the new commits, rerun the tests, and overwrite the
report. Fix only blockers and should-fix findings; nits go in the PR description,
never into a fix round. In a stacked series, merge the stack up once after all
pieces' fixes are in; a piece whose only new commit is a merge gets a test run,
then a short re-review of that merge, not a full review.
