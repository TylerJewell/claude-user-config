#!/bin/bash
# Fires after Edit/Write. If a frontend source file was edited, reminds about the build step.
# Designed for Angular + Akka projects where built assets must be copied to Java static resources.
input=$(cat)
file_path=$(echo "$input" | python3 -c "
import sys, json
try:
    d = json.loads(sys.stdin.read())
    print(d.get('tool_input', {}).get('file_path', ''))
except:
    print('')
" 2>/dev/null || echo "")

if echo "$file_path" | grep -q '/frontend/src/'; then
    echo "FRONTEND SOURCE EDITED: $file_path" >&2
    echo "Next step: cd compliance-surface/frontend && npx ng build --configuration development && cp -r dist/frontend/browser/* ../src/main/resources/static-resources/" >&2
    echo "Java restart needed only if .java or application.conf files also changed." >&2
    exit 1  # Non-blocking — first line of stderr shown in transcript
fi
exit 0
