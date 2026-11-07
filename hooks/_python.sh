#!/bin/bash
# Sourced by the hooks and installers. Sets PYTHON to a command that runs Python 3, or leaves it empty.
#
# On Windows, `python3` and `python` are usually Microsoft Store stubs that print an
# install prompt and do nothing, so the `py` launcher is tried first. Each candidate is
# run, not just looked up, so a stub is skipped.

PYTHON=""
for candidate in "py -3" python3 python; do
    if $candidate -c 'import sys; sys.exit(0 if sys.version_info[0] == 3 else 1)' >/dev/null 2>&1; then
        PYTHON="$candidate"
        break
    fi
done
