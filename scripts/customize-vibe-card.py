#!/usr/bin/env python3

import re
from pathlib import Path


README_PATH = Path("README.md")
SVG_PATH = Path("vibe-card.svg")


def replace_model(match: re.Match[str], counts: list[int]) -> str:
    counts[0] += 1
    if counts[0] == 1:
        return ">opus-4.6 "
    if counts[0] == 2:
        return ">sonnet-4.6 "
    return match.group(0)


def customize_readme() -> None:
    content = README_PATH.read_text(encoding="utf-8")
    content = re.sub(
        r"<!-- VIBE-DASHBOARD:START -->.*?<!-- VIBE-DASHBOARD:END -->",
        "<!-- VIBE-DASHBOARD:START -->\n[![Vibe Dashboard](./vibe-card.svg)](https://aliencoder.tistory.com/)\n<!-- VIBE-DASHBOARD:END -->",
        content,
        flags=re.DOTALL,
    )
    README_PATH.write_text(content, encoding="utf-8")


def customize_svg() -> None:
    content = SVG_PATH.read_text(encoding="utf-8")
    content = content.replace("🎸", "⚡")
    counts = [0]
    content = re.sub(r">4-6 ", lambda match: replace_model(match, counts), content)
    content = content.replace("translate(25, 220)", "translate(25, 245)")
    content = content.replace('height="374"', 'height="399"')
    content = content.replace("0 0 900 374", "0 0 900 399")
    content = content.replace('height="373"', 'height="398"')
    content = content.replace('y="354"', 'y="379"')
    content = content.replace(
        'href="https://github.com/mjyoo2/VibeDashboard"',
        'href="https://aliencoder.tistory.com/"',
    )
    SVG_PATH.write_text(content, encoding="utf-8")


if README_PATH.exists():
    customize_readme()

if SVG_PATH.exists():
    customize_svg()

print("Customized VibeDashboard assets")
