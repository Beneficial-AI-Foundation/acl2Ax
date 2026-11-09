#!/usr/bin/env python3
"""Sum the token usage of subagent transcripts of a Claude Code session.

Usage: usage.py <session-transcript-dir> [--agent ID ...] [--since ISO] [--until ISO] [--json]

  <session-transcript-dir>  the directory <session-uuid>/ beside <session-uuid>.jsonl, which
                            holds subagents/agent-<id>.jsonl
  --agent                   restrict to these agent ids (default: every subagent file)
  --since, --until          keep only messages whose timestamp lies in the window (UTC, ISO 8601)
  --json                    print JSON instead of a table

Each assistant message is counted once, by its message id. Token counts are the four fields of
the message `usage` object. The script does not compute dollars, because prices are not in the
transcript.
"""
import argparse
import glob
import json
import os
import sys

FIELDS = ["input_tokens", "cache_creation_input_tokens", "cache_read_input_tokens", "output_tokens"]


def in_window(ts, since, until):
    if ts is None:
        return False
    if since and ts < since:
        return False
    if until and ts > until:
        return False
    return True


def sum_file(path, since, until):
    seen = {}
    for line in open(path, encoding="utf-8"):
        try:
            rec = json.loads(line)
        except json.JSONDecodeError:
            continue
        msg = rec.get("message")
        if not isinstance(msg, dict) or "usage" not in msg:
            continue
        if not in_window(rec.get("timestamp"), since, until):
            continue
        mid = msg.get("id") or rec.get("uuid")
        if mid not in seen:
            seen[mid] = (msg.get("model", "unknown"), msg["usage"])
    totals = {f: 0 for f in FIELDS}
    models = set()
    for model, usage in seen.values():
        models.add(model)
        for f in FIELDS:
            totals[f] += usage.get(f, 0) or 0
    totals["messages"] = len(seen)
    totals["models"] = sorted(models)
    totals["total_tokens"] = sum(totals[f] for f in FIELDS)
    return totals


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("session_dir")
    ap.add_argument("--agent", action="append", default=[])
    ap.add_argument("--since")
    ap.add_argument("--until")
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()

    sub = os.path.join(a.session_dir, "subagents")
    files = sorted(glob.glob(os.path.join(sub, "agent-*.jsonl")))
    if a.agent:
        files = [f for f in files if any(os.path.basename(f) == f"agent-{i}.jsonl" for i in a.agent)]
    if not files:
        sys.exit("no subagent transcripts found")

    result = {}
    for f in files:
        agent = os.path.basename(f)[len("agent-"):-len(".jsonl")]
        result[agent] = sum_file(f, a.since, a.until)
    grand = {f: sum(r[f] for r in result.values()) for f in FIELDS + ["total_tokens", "messages"]}
    result["_total"] = grand

    if a.json:
        print(json.dumps(result, indent=1))
        return
    print(f"{'agent':<20}{'input':>10}{'cache_new':>12}{'cache_read':>13}{'output':>10}{'total':>12}  models")
    for agent, r in result.items():
        print(f"{agent:<20}{r.get('input_tokens',0):>10}{r.get('cache_creation_input_tokens',0):>12}"
              f"{r.get('cache_read_input_tokens',0):>13}{r.get('output_tokens',0):>10}{r.get('total_tokens',0):>12}  "
              f"{','.join(r.get('models', [])) if agent != '_total' else ''}")


if __name__ == "__main__":
    main()
