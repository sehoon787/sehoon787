#!/usr/bin/env python3

import re
from pathlib import Path


svg_path = Path("vibe-card.svg")
content = svg_path.read_text(encoding="utf-8")

content = content.replace("🎸", "⚡")
content = content.replace("VibeDashboard", "AI Dashboard")

count = 0


def replace_model(match: re.Match[str]) -> str:
    global count
    count += 1
    if count == 1:
        return ">opus-4.6 "
    if count == 2:
        return ">sonnet-4.6 "
    return match.group(0)


content = re.sub(r">4-6 ", replace_model, content)
content = content.replace("translate(25, 220)", "translate(25, 245)")
content = content.replace('height="374"', 'height="399"')
content = content.replace("0 0 900 374", "0 0 900 399")
content = content.replace('height="373"', 'height="398"')
content = content.replace('y="354"', 'y="379"')
content = re.sub(r" • Powered by <a[^>]*>[^<]*</a>", "", content)

svg_path.write_text(content, encoding="utf-8")
print("Customized vibe-card.svg")
