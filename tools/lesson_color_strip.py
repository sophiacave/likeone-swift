#!/usr/bin/env python3
"""P4: strip inline `color:` declarations from PROSE-context elements in lesson HTML.

Keeps colors in:
  - <pre> blocks (syntax highlighting)
  - visual containers (.lo-vis, .lesson-visual, .demo-container, .demo-block,
    .flash-*, .quiz-*, .lo-versus, .lo-steps)

Removes only the `color:` declaration; other style declarations are preserved.
Drops the style attribute entirely if it becomes empty.

Usage: lesson_color_strip.py [--apply]   (default is dry-run)
"""
import re, sys
from pathlib import Path

LESSONS = Path.home() / "likeone-swift/Resources/Content/lessons"
VISUAL_CLASSES = re.compile(
    r'class="[^"]*\b(lo-vis|lesson-visual|demo-container|demo-block|flash-|quiz-|lo-versus|lo-steps?)'
)
TAG_RE = re.compile(r"<(/?)([a-zA-Z][a-zA-Z0-9-]*)((?:[^>\"']|\"[^\"]*\"|'[^']*')*)>")
STYLE_ATTR = re.compile(r'\sstyle="([^"]*)"')
# match a color declaration but NOT background-color / border-color / etc.
COLOR_DECL = re.compile(r'(?:^|;)\s*(?<![a-z-])color\s*:[^;"]*', re.I)
HAS_COLOR = re.compile(r'(?<![a-z-])color\s*:', re.I)
VOID_TAGS = {"br", "img", "hr", "input", "meta", "link", "source"}


def strip_color(style_value):
    parts = [p.strip() for p in style_value.split(";")]
    kept = [p for p in parts if p and not re.match(r"^color\s*:", p, re.I)]
    return ";".join(kept)


def transform(html):
    """Return (new_html, n_stripped)."""
    pre_depth = 0
    visual_depth = []
    depth = 0
    edits = []  # (start, end, replacement)
    n = 0
    for m in TAG_RE.finditer(html):
        closing, tag = m.group(1), m.group(2).lower()
        if closing:
            depth -= 1
            if tag == "pre" and pre_depth:
                pre_depth -= 1
            if visual_depth and depth < visual_depth[-1]:
                visual_depth.pop()
            continue
        full = m.group(0)
        if tag == "pre":
            pre_depth += 1
        if VISUAL_CLASSES.search(full):
            visual_depth.append(depth + 1)
        if not pre_depth and not visual_depth:
            sm = STYLE_ATTR.search(full)
            if sm and HAS_COLOR.search(sm.group(1)):
                new_style = strip_color(sm.group(1))
                if new_style:
                    new_tag = full[: sm.start()] + f' style="{new_style}"' + full[sm.end():]
                else:
                    new_tag = full[: sm.start()] + full[sm.end():]
                edits.append((m.start(), m.end(), new_tag))
                n += 1
        if tag not in VOID_TAGS:
            depth += 1
    if not edits:
        return html, 0
    out = []
    last = 0
    for s, e, rep in edits:
        out.append(html[last:s])
        out.append(rep)
        last = e
    out.append(html[last:])
    return "".join(out), n


def main():
    apply = "--apply" in sys.argv
    total = 0
    changed = 0
    for f in sorted(LESSONS.rglob("*.html")):
        html = f.read_text(encoding="utf-8", errors="replace")
        new, n = transform(html)
        if n:
            changed += 1
            total += n
            if apply:
                f.write_text(new, encoding="utf-8")
    mode = "APPLIED" if apply else "DRY-RUN"
    print(f"[{mode}] {total} color declarations stripped across {changed} files")


if __name__ == "__main__":
    main()
