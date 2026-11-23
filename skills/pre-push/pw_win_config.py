"""Write playwright.win.config.ts beside playwright.config.ts with the lsof pre-kills removed."""
import re
import sys
from pathlib import Path

src = Path(sys.argv[1])
text = src.read_text(encoding="utf-8")
out, n = re.subn(r"\(lsof -ti:\$\{\w+\} \| xargs kill -9 2>/dev/null \|\| true\) && ", "", text)
src.with_name("playwright.win.config.ts").write_text(out, encoding="utf-8")
print(f"removed {n} pre-kill(s)")
