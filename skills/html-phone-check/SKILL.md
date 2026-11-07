---
name: html-phone-check
description: Check that an HTML page opens and reads correctly on a phone before it is sent to anyone. Renders the file at 320, 375 and 430 px with scripts on and off, in WebKit (iPhone Safari and in-app viewers) and Chromium, and reports sideways scroll, missing text, script errors and invisible text. Use before sending an HTML deliverable (an IOI, a deck, a battlecard, a page) to a person, when someone says a page does not open or looks wrong on a phone, or after changing a page's layout or scripts.
---

# HTML phone check

A page that looks right on a laptop can be blank on a phone. Mail and file previews run no scripts, and phone mail apps often cannot render an `.html` attachment at all.

## Run it

```
py -3 ~/.claude/skills/html-phone-check/phone_check.py <file.html> --out <folder>
```

Setup once per machine: `py -3 -m pip install playwright`, then `py -3 -m playwright install chromium webkit`.

It prints one line per engine, mode and width, and saves a first-screen screenshot at 375 px. Read the screenshots; the numbers do not show a page that looks wrong. Exit status 1 means sideways scroll, no text, or a script error.

## What the output means

- **SIDEWAYS SCROLL:** content wider than the screen. Fix the layout.
- **NO TEXT** with scripts off: the page hides content until a script runs. Hidden starting states belong under a class the script sets.
- **invisible N** with scripts on is normal for reveal-on-scroll text; with scripts off it must be 0.
- WebKit missing: install it, because Chromium alone does not show iPhone behaviour.

## What it does not cover

A real phone and the app a customer uses. An `.html` attachment may not open in a mail app whatever the page does; a link that opens in the browser is the reliable way to send a page.
