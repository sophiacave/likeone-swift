#!/usr/bin/env python3
"""P4 audit: classify inline-colored elements in lesson HTML by context.

Contexts:
  - code:   inside <pre>...</pre> (syntax highlighting — KEEP)
  - visual: inside .lo-vis / .lesson-visual / .demo-container / .flash-* / .quiz-* (intentional — KEEP)
  - prose:  everything else (LEAK — strip)
"""
import re, sys, json
from pathlib import Path
from collections import Counter

LESSONS = Path.home() / "likeone-swift/Resources/Content/lessons"
VISUAL_CLASSES = re.compile(
    r'class="[^"]*\b(lo-vis|lesson-visual|demo-container|demo-block|flash-|quiz-|lo-versus|lo-steps?)'
)
TAG_RE = re.compile(r"<(/?)([a-zA-Z][a-zA-Z0-9-]*)((?:[^>\"']|\"[^\"]*\"|'[^']*')*)>")
COLOR_IN_STYLE = re.compile(r'style="[^"]*(?<![a-z-])color\s*:', re.I)

def classify(html):
    """Yield (tag, context, pos) for every element with inline color."""
    pre_depth = 0
    visual_depth = []  # stack of depths where a visual container opened
    depth = 0
    for m in TAG_RE.finditer(html):
        closing, tag, attrs = m.group(1), m.group(2).lower(), m.group(3)
        void = tag in ("br", "img", "hr", "input", "meta", "link")
        if closing:
            depth -= 1
            if tag == "pre" and pre_depth:
                pre_depth -= 1
            if visual_depth and depth < visual_depth[-1]:
                visual_depth.pop()
            continue
        if tag == "pre":
            pre_depth += 1
        if VISUAL_CLASSES.search(m.group(0)):
            visual_depth.append(depth + 1)
        has_color = COLOR_IN_STYLE.search(m.group(0))
        if has_color:
            if pre_depth:
                ctx = "code"
            elif visual_depth:
                ctx = "visual"
            else:
                ctx = "prose"
            yield tag, ctx, m.start()
        if not void:
            depth += 1

def main():
    by_ctx = Counter()
    by_tag_prose = Counter()
    prose_files = Counter()
    samples = []
    files = sorted(LESSONS.rglob("*.html"))
    for f in files:
        html = f.read_text(encoding="utf-8", errors="replace")
        for tag, ctx, pos in classify(html):
            by_ctx[ctx] += 1
            if ctx == "prose":
                by_tag_prose[tag] += 1
                prose_files[str(f.relative_to(LESSONS))] += 1
                if len(samples) < 15:
                    samples.append(f"{f.relative_to(LESSONS)}: <{tag}> {html[pos:pos+120]!r}")
    print(f"files scanned: {len(files)}")
    print(f"by context: {dict(by_ctx)}")
    print(f"prose by tag: {dict(by_tag_prose.most_common(15))}")
    print(f"files with prose leaks: {len(prose_files)}")
    print("top files:", json.dumps(prose_files.most_common(10), indent=1))
    print("\nSAMPLES:")
    for s in samples:
        print(" ", s)

if __name__ == "__main__":
    main()
