#!/usr/bin/env python3

import json
import sys
from datetime import datetime
from pathlib import Path


def parse_date(value: str) -> str:
    for fmt in ("%Y-%m-%d", "%b %d, %Y"):
        try:
            return datetime.strptime(value, fmt).strftime("%Y-%m-%d")
        except ValueError:
            continue
    return value


def model_total_tokens(model: dict) -> int:
    total = model.get("totalTokens")
    if total is not None:
        return int(total)

    return int(model.get("inputTokens", 0)) + int(model.get("cachedInputTokens", 0)) + int(model.get("outputTokens", 0)) + int(model.get("reasoningOutputTokens", 0))


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: normalize-codex-to-ccusage.py <input> <output>", file=sys.stderr)
        return 1

    src = Path(sys.argv[1])
    dst = Path(sys.argv[2])
    raw = json.loads(src.read_text(encoding="utf-8"))

    by_day: dict[str, dict[str, float | int]] = {}
    by_model: dict[str, dict[str, float | int]] = {}

    total_cost = 0.0
    total_input = 0
    total_output = 0
    total_cache_read = 0

    for day in raw.get("daily", []):
        date_key = parse_date(str(day.get("date", "")))
        day_cost = float(day.get("costUSD", 0.0) or 0.0)
        day_input = int(day.get("inputTokens", 0) or 0)
        day_output = int(day.get("outputTokens", 0) or 0) + int(day.get("reasoningOutputTokens", 0) or 0)
        day_cache_read = int(day.get("cachedInputTokens", 0) or 0)
        day_total_tokens = int(day.get("totalTokens", 0) or 0)

        by_day[date_key] = {
            "cost": by_day.get(date_key, {}).get("cost", 0.0) + day_cost,
            "tokens": by_day.get(date_key, {}).get("tokens", 0) + day_total_tokens,
        }

        models = day.get("models", {}) or {}
        token_denominator = sum(model_total_tokens(model) for model in models.values()) or 1

        for model_name, model_stats in models.items():
            normalized_name = f"{model_name} (Codex)"
            model_tokens = model_total_tokens(model_stats)
            model_cost = day_cost * (model_tokens / token_denominator)
            stats = by_model.setdefault(normalized_name, {"cost": 0.0, "inputTokens": 0, "outputTokens": 0})
            stats["cost"] += model_cost
            stats["inputTokens"] += int(model_stats.get("inputTokens", 0) or 0) + int(model_stats.get("cachedInputTokens", 0) or 0)
            stats["outputTokens"] += int(model_stats.get("outputTokens", 0) or 0) + int(model_stats.get("reasoningOutputTokens", 0) or 0)

        total_cost += day_cost
        total_input += day_input
        total_output += day_output
        total_cache_read += day_cache_read

    totals = raw.get("totals", {}) or {}
    if totals:
        total_cost = float(totals.get("costUSD", total_cost) or total_cost)
        total_input = int(totals.get("inputTokens", total_input) or total_input)
        total_output = int(totals.get("outputTokens", 0) or 0) + int(totals.get("reasoningOutputTokens", 0) or 0) or total_output
        total_cache_read = int(totals.get("cachedInputTokens", total_cache_read) or total_cache_read)

    normalized = {
        "totalCost": total_cost,
        "totalInputTokens": total_input,
        "totalOutputTokens": total_output,
        "totalCacheCreationInputTokens": 0,
        "totalCacheReadInputTokens": total_cache_read,
        "byModel": by_model,
        "byDay": by_day,
    }

    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_text(json.dumps(normalized, ensure_ascii=True), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
