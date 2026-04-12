#!/bin/bash
# Fires before akka_local_start. Blocks if the Akka local runtime is already running (port 9889).
# The Akka local runtime is a SHARED daemon — restarting it kills services in all Claude sessions.
if netstat -an 2>/dev/null | grep -qiE '[:.]9889[^0-9].*(LISTEN|LISTENING)'; then
    echo "BLOCKED: Akka local runtime already running on port 9889." >&2
    echo "Calling akka_local_start would kill ALL services running in other Claude sessions." >&2
    echo "Instead: use akka_local_run_service to add a service to the existing daemon." >&2
    echo "To inspect what is running: call akka_local_status first." >&2
    exit 2  # Blocking — denies the tool call
fi
exit 0
