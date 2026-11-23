#!/bin/bash
# Fires before Bash/PowerShell tool calls. Blocks `git push` of a feature branch
# until the /pre-push checks report for that branch exists, is newer than the
# branch tip and says "Checks: PASS". In an akka-org repo it also requires an
# /akka-pr-review report that is newer than the tip and says READY TO PUSH.
# lightbend/kalix-console needs the checks report only.
#
# A review written before the last few commits describes code that is no longer
# being pushed, so staleness is treated the same as absence.
#
# Escape hatches: prefix the command with AKKA_PR_REVIEW_SKIP=1 (skips both) or
# PRE_PUSH_SKIP=1 (skips the checks report only).
#
# Exits silently for everything that isn't such a push.

. "$(dirname "$0")/_python.sh"
[ -n "$PYTHON" ] || exit 0

FIELDS=$($PYTHON -c "
import json, sys
d = json.load(sys.stdin)
print((d.get('tool_input') or {}).get('command', '').replace(chr(10), ' '))
print(d.get('cwd') or '')
" 2>/dev/null) || exit 0

COMMAND=$(printf '%s\n' "$FIELDS" | sed -n 1p)
CWD=$(printf '%s\n' "$FIELDS" | sed -n 2p)

case "$COMMAND" in
    *AKKA_PR_REVIEW_SKIP=1*) exit 0 ;;
    *"git push"*) ;;
    *) exit 0 ;;
esac

[ -n "$CWD" ] && cd "$CWD" 2>/dev/null

REMOTE=$(git remote get-url origin 2>/dev/null) || exit 0
case "$REMOTE" in
    *github.com/akka/*|*github.com:akka/*) NEEDS_REVIEW=1 ;;
    *github.com/lightbend/kalix-console*|*github.com:lightbend/kalix-console*) NEEDS_REVIEW= ;;
    *) exit 0 ;;
esac

BRANCH=$(git branch --show-current 2>/dev/null)
[ -z "$BRANCH" ] && exit 0

# Pushing an integration branch isn't opening a PR, so there is nothing to review.
# main/master count as integration branches even when origin/HEAD is unset.
DEFAULT=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
case "$BRANCH" in
    main|master|"${DEFAULT#origin/}") exit 0 ;;
esac

REPO=$(basename -s .git "$REMOTE")
REPORT="$HOME/.claude/reviews/$REPO-${BRANCH//\//-}-review.md"
CHECKS="$HOME/.claude/reviews/$REPO-${BRANCH//\//-}-checks.md"
TIP=$(git log -1 --format=%ct 2>/dev/null)

written() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null; }

case "$COMMAND" in
    *PRE_PUSH_SKIP=1*) ;;
    *)
        fail_checks() {
            echo "BLOCKED: $1" >&2
            echo "Run /pre-push on this branch, then push." >&2
            echo "  repo:   $REPO  branch: $BRANCH" >&2
            echo "  report: $CHECKS" >&2
            echo "To push without the checks: prefix the command with PRE_PUSH_SKIP=1" >&2
            exit 2
        }
        [ -f "$CHECKS" ] || fail_checks "no pre-push checks report for this branch."
        W=$(written "$CHECKS")
        if [ -n "$TIP" ] && [ -n "$W" ] && [ "$W" -lt "$TIP" ]; then
            fail_checks "the checks report predates the branch tip."
        fi
        head -n 5 "$CHECKS" | grep -q '^Checks: PASS' || fail_checks "the checks report does not say Checks: PASS."
        ;;
esac

[ -n "$NEEDS_REVIEW" ] || exit 0

block() {
    echo "BLOCKED: $1" >&2
    echo "Run /akka-pr-review on this branch, then push." >&2
    echo "  repo:   $REPO (akka org)" >&2
    echo "  branch: $BRANCH" >&2
    echo "  report: $REPORT" >&2
    echo "To push without a review: prefix the command with AKKA_PR_REVIEW_SKIP=1" >&2
    exit 2  # Blocking — denies the tool call
}

[ -f "$REPORT" ] || block "no independent review report for this branch."

WRITTEN=$(written "$REPORT")
if [ -n "$TIP" ] && [ -n "$WRITTEN" ] && [ "$WRITTEN" -lt "$TIP" ]; then
    block "the review report predates the branch tip — it reviewed different code."
fi

VERDICT=$(head -n 20 "$REPORT" | grep -m1 -oE 'READY TO PUSH|NEEDS WORK|NEEDS HUMAN DECISION')
if [ -n "$VERDICT" ] && [ "$VERDICT" != "READY TO PUSH" ]; then
    block "the review verdict is $VERDICT."
fi

exit 0
