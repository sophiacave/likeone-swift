#!/usr/bin/env python3
"""Convert ASCII tables in <pre> blocks to .lo-table HTML.

Scans lesson HTML files for <pre> blocks containing tabular data
(box-drawing characters or column-aligned text) and converts them
to semantic HTML tables with .lo-table styling.

Usage:
    python scripts/convert-ascii-tables.py --dry-run   # Preview changes
    python scripts/convert-ascii-tables.py              # Apply changes
"""

import re
import sys
from pathlib import Path

LESSONS_DIR = Path(__file__).parent.parent / "Resources" / "Content" / "lessons"
TABLE_CHARS = re.compile(r"[─━═│┌┐└┘├┤┬┴┼╔╗╚╝╠╣╦╩╬]")
SPAN_TAG = re.compile(r'<span[^>]*style="color:([^"]*)"[^>]*>([^<]*)</span>')
COLUMN_SEP = re.compile(r"  {2,}")  # 2+ spaces = column boundary


def strip_html(text: str) -> str:
    """Remove HTML tags but preserve text content."""
    return re.sub(r"<[^>]+>", "", text)


def extract_color(html_line: str) -> list[tuple[str, str]]:
    """Extract (color, text) pairs from a line with <span> tags."""
    parts = []
    pos = 0
    for m in SPAN_TAG.finditer(html_line):
        # Text before the span
        before = strip_html(html_line[pos:m.start()])
        if before.strip():
            parts.append(("", before.strip()))
        parts.append((m.group(1), m.group(2)))
        pos = m.end()
    # Text after last span
    after = strip_html(html_line[pos:])
    if after.strip():
        parts.append(("", after.strip()))
    return parts


def parse_ascii_table(pre_content: str) -> dict | None:
    """Parse an ASCII table from pre/code block content.

    Returns dict with 'title', 'headers', 'rows', 'header_colors' or None.
    """
    # Strip code tags
    content = re.sub(r"</?code>", "", pre_content)
    lines = content.split("\n")

    # Find the separator line (─── or === or ---)
    sep_idx = None
    for i, line in enumerate(lines):
        clean = strip_html(line).strip()
        if TABLE_CHARS.search(clean) and len(clean) > 5:
            sep_idx = i
            break

    if sep_idx is None:
        return None

    # Title is everything before the header line
    title = ""
    header_line_idx = sep_idx - 1
    if header_line_idx >= 0:
        # Check for a title line above the header
        for i in range(header_line_idx):
            t = strip_html(lines[i]).strip()
            if t and len(t) > 3:
                title = t
                break

    # Parse header line
    header_raw = lines[header_line_idx] if header_line_idx >= 0 else ""
    header_parts = extract_color(header_raw)
    if not header_parts:
        header_text = strip_html(header_raw).strip()
        headers = COLUMN_SEP.split(header_text)
        headers = [h.strip() for h in headers if h.strip()]
        header_colors = [""] * len(headers)
    else:
        headers = [p[1].strip() for p in header_parts if p[1].strip()]
        header_colors = [p[0] for p in header_parts if p[1].strip()]

    if len(headers) < 2:
        return None

    # Parse data rows (everything after separator)
    rows = []
    for line in lines[sep_idx + 1:]:
        clean = strip_html(line).strip()
        if not clean or TABLE_CHARS.search(clean):
            continue
        cells = COLUMN_SEP.split(clean)
        cells = [c.strip() for c in cells if c.strip()]
        if cells:
            rows.append(cells)

    if not rows:
        return None

    return {
        "title": title,
        "headers": headers,
        "rows": rows,
        "header_colors": header_colors,
    }


def color_to_class(color: str) -> str:
    """Map CSS color to .lo-table class name."""
    color_map = {
        "#34d399": "col-green",
        "#8b5cf6": "col-purple",
        "#c084fc": "col-purple",
        "#38bdf8": "col-blue",
        "#fb923c": "col-orange",
    }
    return color_map.get(color.strip(), "")


def table_to_html(parsed: dict) -> str:
    """Generate .lo-table HTML from parsed table data."""
    lines = ['<div class="lo-table-wrap">']
    lines.append('  <table class="lo-table">')

    if parsed["title"]:
        lines.append(f'    <caption>{parsed["title"]}</caption>')

    # Header
    lines.append("    <thead>")
    lines.append("      <tr>")
    for i, header in enumerate(parsed["headers"]):
        cls = ""
        if i < len(parsed["header_colors"]):
            cls = color_to_class(parsed["header_colors"][i])
        cls_attr = f' class="{cls}"' if cls else ""
        lines.append(f"        <th{cls_attr}>{header}</th>")
    lines.append("      </tr>")
    lines.append("    </thead>")

    # Body
    lines.append("    <tbody>")
    for row in parsed["rows"]:
        lines.append("      <tr>")
        for cell in row:
            lines.append(f"        <td>{cell}</td>")
        # Pad if row has fewer cells than headers
        for _ in range(len(parsed["headers"]) - len(row)):
            lines.append("        <td></td>")
        lines.append("      </tr>")
    lines.append("    </tbody>")

    lines.append("  </table>")
    lines.append("</div>")

    return "\n".join(lines)


def find_pre_tables(html: str) -> list[tuple[int, int, str, dict]]:
    """Find <pre> blocks containing ASCII tables. Returns (start, end, original, parsed)."""
    results = []

    # Match the full container (might be wrapped in a div)
    # Pattern: <div ...><pre ...><code>...</code></pre></div>
    # Or just: <pre>...</pre>
    pattern = re.compile(
        r'(<div[^>]*>\s*<pre[^>]*><code>.*?</code></pre>\s*</div>|<pre[^>]*>.*?</pre>)',
        re.DOTALL,
    )

    for m in pattern.finditer(html):
        block = m.group(0)
        if not TABLE_CHARS.search(block):
            continue

        parsed = parse_ascii_table(block)
        if parsed and len(parsed["rows"]) >= 2:
            results.append((m.start(), m.end(), block, parsed))

    return results


def process_file(filepath: Path, dry_run: bool = True) -> int:
    """Process a single HTML file. Returns number of tables converted."""
    html = filepath.read_text()
    tables = find_pre_tables(html)

    if not tables:
        return 0

    converted = 0
    # Process in reverse order to preserve positions
    for start, end, original, parsed in reversed(tables):
        new_html = table_to_html(parsed)

        if dry_run:
            print(f"  Would convert: {parsed['title'] or 'untitled'} "
                  f"({len(parsed['headers'])} cols, {len(parsed['rows'])} rows)")
            print(f"    Headers: {parsed['headers']}")
        else:
            html = html[:start] + new_html + html[end:]

        converted += 1

    if not dry_run and converted > 0:
        filepath.write_text(html)

    return converted


def main():
    dry_run = "--dry-run" in sys.argv

    if dry_run:
        print("DRY RUN — no files will be modified\n")
    else:
        print("CONVERTING ASCII tables to .lo-table HTML\n")

    total = 0
    files_changed = 0

    for html_file in sorted(LESSONS_DIR.rglob("*.html")):
        if "research" in str(html_file):
            continue

        count = process_file(html_file, dry_run=dry_run)
        if count > 0:
            rel = html_file.relative_to(LESSONS_DIR)
            print(f"{'[preview]' if dry_run else '[converted]'} {rel}: {count} table(s)")
            total += count
            files_changed += 1

    print(f"\n{'Would convert' if dry_run else 'Converted'}: "
          f"{total} tables across {files_changed} files")


if __name__ == "__main__":
    main()
