---
name: pre-push
description: Run the checks a repository's CI runs before pushing a branch, and write the checks report the push hook requires. Use before every push to akka/cli, lightbend/kalix-console, akka/akka-sdk or akka/ai-marketplace, before /akka-pr-review, and when the user asks to "check before push" or "run the CI checks locally".
---

# Pre-push checks

Most CI failures on these repositories come from a check that could have run locally: format, lint, the race
detector, the full unit suite, the integration tests, Vale. Run that repository's list below, in order, on the
branch about to be pushed. Run each list in full. Stop at the first failure, fix it, and start the list again.

Run this before `/akka-pr-review`, so the reviewer sees code that already passes CI's mechanical checks.

## Stacks

For a stack of branches, run the list on the **top** branch once its lower branches are merged into it. Push
nothing until the top passes, because a single cause otherwise fails every branch of the stack.

Write a report for each branch pushed. A lower branch whose code is unchanged in the top can carry the top's
result, with a line saying so.

## Full or scoped

Run the **full** list for the repository when any of these is true:
- the branch has never been pushed;
- the push includes a merge from another branch;
- the change touches shared code (in kalix-console: `src/core`, the mode and viability files, the shell, the
  demo layer or shared packages; in akka/cli: a package other code imports widely);
- CI failed on the branch's last push.

Otherwise, for a follow-up commit on a branch whose last push passed, run the **scoped** list: the tests beside
the changed files (in kalix-console, `scripts/related-tests.sh` or the changed folders' vitest), the type check,
and lint and prettier on the changed files. CI runs the rest. Write the report as `Checks: PASS (scoped)`, naming
what ran; the push hook accepts it.

## Agents in parallel

When several agents work on separate branches at the same time, each runs only the tests of the folders it
changed, plus type checks and lint on changed files. The full suites (the console's vitest suite starts about
22 workers; Playwright uses fixed ports) then run one branch at a time, after the agents finish. Five full
console suites at once start over a hundred processes, and each one times out.

## akka/cli

Run from the repository root. `api/` must exist: copy it from another checkout, and never commit it.

1. goimports on the committed content of each changed Go file must print nothing. Files under `testdata/`
   count. gofmt alone does not catch import grouping. Check the committed content, because a Windows checkout
   with `autocrlf=true` lists every file as unformatted:

   ```bash
   for f in $(git diff --name-only --diff-filter=ACM origin/main...HEAD -- '*.go'); do
     git show "HEAD:$f" | go tool goimports -l 2>/dev/null | sed "s|<standard input>|$f|"
   done
   ```
2. `go vet` on the changed packages.
3. `go tool revive -config revive.toml -set_exit_status` on the changed packages. Revive flags these:
   - an exported name whose doc comment does not start with the name;
   - an initialism in the wrong case (`HTTP`, `ID`, `SLA`);
   - a name that stutters with its package (`record.RecordOf`);
   - a `context.Context` that is not the first parameter.
4. The race detector, in Linux, because cgo is unavailable on Windows:

   ```bash
   MSYS_NO_PATHCONV=1 docker run --rm -v "$(pwd -W 2>/dev/null || pwd):/src" -w /src \
     -v "$(go env GOMODCACHE):/go/pkg/mod" -e GOPROXY=off -e GOFLAGS=-mod=mod \
     golang:1.26 go test -race -count=1 <changed packages and their importers>
   ```

   `MSYS_NO_PATHCONV=1` stops Git Bash from rewriting `/src` into a Windows path. The host's module cache is
   mounted with `GOPROXY=off`, because the private akka-optimize module cannot be
   fetched inside the container. Run `go mod download` on the host first if the cache is cold. In a git worktree,
   `.git` points at a host path, so a test that runs git fails in the container with "not in a git repository":
   skip it there with `-skip <Test>`, run it on the host, and name it in the report.

   Races come from test fakes shared with goroutines and from package variables that tests overwrite. A run
   that passes locally without `-race` proves nothing about them.
5. For a new or changed test that waits, sorts, or ranges over a map: `go test -count=20 -run <Test>` must pass
   all twenty runs.

## lightbend/kalix-console

Run from the repository root.

1. Prettier on the committed content of every changed file (JSON fixtures and workflow YAML count). On a Windows
   checkout with `autocrlf=true`, `pnpm prettier` flags thousands of files for their line endings, so check what
   is committed:

   ```bash
   for f in $(git diff --name-only --diff-filter=ACM origin/main...HEAD | grep -E '\.(ts|tsx|js|mjs|json|ya?ml|md|css)$'); do
     git show "HEAD:$f" | npx prettier --stdin-filepath "$f" --check >/dev/null 2>&1 || echo "unformatted: $f"
   done
   ```

   Run prettier from inside the package that owns the file (`cd apps/local-console`, with the path relative to
   it), because CI runs it there with that package's config and `.prettierignore`; run from the repository root it
   flags files CI accepts. `apps/local-console/.prettierignore` skips `src/core/demo/fixtures`.
2. `pnpm lint` (type checks, test type checks and eslint). On Windows, `check-types` sets `NODE_OPTIONS=` in
   cmd syntax and fails; run it with Git Bash as the script shell:
   `npm_config_script_shell="C:\Program Files\Git\bin\bash.exe" pnpm lint`.
3. The full unit suite, `pnpm test:unit`, once with `apps/local-console/.env.local` **moved aside**. CI has no
   `.env.local`: a test that imports `core/data/localApi.ts` under the node environment fails there with
   "window is not defined". Repository-wide tests such as `links.test.ts` run only in the full suite, never in
   `related-tests.sh`. Put `.env.local` back afterwards.
4. `pnpm -F @akka-console/local test:integration` (Playwright). It fails when a page change breaks a guided demo
   step, a mock answer, or production-mode gray-outs. On Windows its web server command pre-kills the port with
   `lsof`, which does not exist. From `apps/local-console`:

   ```bash
   py -3 ~/.claude/skills/pre-push/pw_win_config.py playwright.config.ts   # writes playwright.win.config.ts
   npx playwright test -c playwright.win.config.ts --reporter=line
   rm -f playwright.win.config.ts; git checkout -- src/routeTree.gen.ts
   ```

   The dev server rewrites `src/routeTree.gen.ts`; restore it, never commit it.
5. ADR self-review. Read the branch's diff against `doc/adr/0005` (never mutate a cached or passed-in array:
   `.reverse()`, `.sort()` and `.splice()` on a query result or an argument need a copy first) and `doc/adr/0012`
   (every table has a loading state and an error state; `isError` is checked; it never returns `null` while
   loading). CI's ADR Lint makes a model call, which this read stands in for.

## akka/akka-sdk

1. `vale --config=docs/.vale.ini` on the changed docs files. Add new terms to the vocabulary rather than
   rewording around a spelling flag, unless the word is wrong.
2. `sbt javafmtCheckAll headerCheckAll scalafmtCheckAll`.
3. `sbt -Dbuild.scalafix "scalafixAll --check"`. It needs `.jvmopts` with `-Xmx3g`; an out-of-memory run
   reports "imports not organized".
4. The changed modules' tests.

## akka/ai-marketplace

1. The repository's own checks, from `.github/workflows`.
2. Every CLI command, flag or template the plugin text names exists in the **released** CLI, not only in an
   unmerged PR. Where it needs an unreleased one, the PR states the release order.

## Report

Write `~/.claude/reviews/<repo>-<branch with / replaced by ->-checks.md`, overwriting any earlier one:

```
Checks: PASS            (or FAIL)
Repo: <repo>  Branch: <branch>  Commit: <short sha>
- <check>: pass | fail | n/a (reason)
```

The push hook refuses a push when this report is missing, older than the branch tip, or does not say
`Checks: PASS`. Write PASS only when every check in the list ran and passed. A check that could not run is
FAIL, with the reason.
