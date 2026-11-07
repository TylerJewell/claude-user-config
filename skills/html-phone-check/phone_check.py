"""Render an HTML file at phone widths, scripts on and off, and report what a reader would get.

    py -3 phone_check.py <file.html> [--out <folder>] [--widths 320,375,430]

For each browser engine that is installed (WebKit is the engine behind iPhone Safari and the in-app
viewers; Chromium covers Android and desktop) and each width, the page is loaded twice: with scripts and
with scripts disabled, which is what a mail or file preview does. It prints the page's scroll width against
the viewport (sideways scroll), the amount of visible text, any script error, and how many text elements
are still invisible. A screenshot of the first screen at 375 wide is saved per engine and mode.

Exit status is 1 when a page scrolls sideways, shows no text, or throws a script error.

Setup, once per machine:
    py -3 -m pip install playwright
    py -3 -m playwright install chromium webkit
"""

import argparse
import pathlib
import sys

from playwright.sync_api import sync_playwright

MEASURE = """() => {
  const d = document.documentElement;
  const hidden = [...document.querySelectorAll('body *')].filter(e => {
    const s = getComputedStyle(e);
    return e.children.length === 0 && e.textContent.trim().length > 30 && parseFloat(s.opacity) === 0;
  }).length;
  return {scrollWidth: d.scrollWidth, clientWidth: d.clientWidth, height: d.scrollHeight,
          text: document.body.innerText.length, invisible: hidden};
}"""


def check(path, out, widths):
    if not pathlib.Path(path).is_file():
        sys.exit(f"file not found: {path} (on Windows give a C:/... path, not a Git Bash /c/... path)")
    url = pathlib.Path(path).resolve().as_uri()
    out.mkdir(parents=True, exist_ok=True)
    problems = 0
    with sync_playwright() as p:
        for name, engine in (("webkit", p.webkit), ("chromium", p.chromium)):
            try:
                browser = engine.launch()
            except Exception:
                print(f"{name}: not installed (py -3 -m playwright install {name})")
                continue
            for scripts in (True, False):
                for w in widths:
                    ctx = browser.new_context(viewport={"width": w, "height": 812}, is_mobile=True, has_touch=True,
                                              device_scale_factor=2, java_script_enabled=scripts)
                    page, errors = ctx.new_page(), []
                    page.on("pageerror", lambda e: errors.append(str(e)[:100]))
                    try:
                        page.goto(url, wait_until="load", timeout=30000)
                        page.wait_for_timeout(800)
                        m = page.evaluate(MEASURE)
                        if w == 375:
                            page.screenshot(path=str(out / f"{name}-{'js' if scripts else 'nojs'}-{w}.png"))
                    except Exception as e:
                        print(f"{name} {'js' if scripts else 'nojs'} {w}: FAILED {str(e)[:100]}")
                        problems += 1
                        ctx.close()
                        continue
                    sideways = m["scrollWidth"] > m["clientWidth"] + 1
                    bad = sideways or m["text"] == 0 or bool(errors)
                    problems += bad
                    print(f"{name:8s} {'js  ' if scripts else 'nojs'} {w:4d}px  text {m['text']:6d}  "
                          f"height {m['height']:6d}  invisible {m['invisible']:3d}"
                          f"{'  SIDEWAYS SCROLL' if sideways else ''}{'  NO TEXT' if m['text'] == 0 else ''}"
                          f"{'  ERRORS ' + '; '.join(errors[:2]) if errors else ''}")
                    ctx.close()
            browser.close()
    return problems


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("file")
    ap.add_argument("--out", default="phone-check")
    ap.add_argument("--widths", default="320,375,430")
    a = ap.parse_args()
    bad = check(a.file, pathlib.Path(a.out), [int(w) for w in a.widths.split(",")])
    print("\nscreenshots:", pathlib.Path(a.out).resolve())
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
