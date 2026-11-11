#!/usr/bin/env python3
"""Merge public game/discord rule lists with local k4reon additions.

Inputs:
  sources.json
  rules/<group>/domains.txt
  rules/<group>/ipcidr.txt
  build/upstream-game-ip.txt   (optional, produced by build scripts)

Outputs:
  build/games-domains.txt
  build/games-ip.txt
  build/discord-domains.txt
  build/discord-ip.txt
"""
import ipaddress
import json
import os
import re
import sys
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BUILD = os.path.join(ROOT, "build")
UA = {"User-Agent": "k4reon-mrs-build/1.0"}
V2FLY_BASE = "https://raw.githubusercontent.com/v2fly/domain-list-community/master/data/"
DOMAIN_RE = re.compile(r"^[a-z0-9]([a-z0-9_-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9_-]*[a-z0-9])?)+$")


def load_denylist():
    path = os.path.join(ROOT, "rules", "denylist.txt")
    if not os.path.exists(path):
        return []
    items = []
    for line in open(path, encoding="utf-8"):
        line = line.strip().lower()
        if line and not line.startswith("#"):
            items.append(line)
    return items


DENY = load_denylist()


def fetch(url):
    import time
    last = None
    for attempt in range(3):
        try:
            req = urllib.request.Request(url, headers=UA)
            with urllib.request.urlopen(req, timeout=60) as r:
                return r.read().decode("utf-8", "replace")
        except Exception as e:
            last = e
            if attempt < 2:
                time.sleep(1 + attempt)
    raise last


def normalize(domain):
    d = domain.strip().lower().rstrip(".")
    if not d:
        return None
    if d.startswith("+."):
        d = d[2:]
    if d.startswith("*."):
        d = d[2:]
    if d.startswith("."):
        d = d[1:]
    if not d or "/" in d or "*" in d or " " in d:
        return None
    if not DOMAIN_RE.match(d):
        return None
    if d in ("localhost", "local"):
        return None
    try:
        ipaddress.ip_address(d)
        return None  # IP, not a domain
    except ValueError:
        pass
    if any(x in d for x in DENY):
        return None
    return d


def parse_plain(text):
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#") or line.startswith("//"):
            continue
        yield line


def parse_loon(text):
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("DOMAIN-SUFFIX,"):
            yield line.split(",", 1)[1]
        elif line.startswith("DOMAIN,"):
            yield line.split(",", 1)[1]
        elif line.startswith("DOMAIN-WILDCARD,"):
            yield line.split(",", 1)[1].lstrip("*.")
        # DOMAIN-KEYWORD / IP-CIDR / etc. are skipped


def parse_v2fly(text, depth=0, seen=None):
    seen = seen if seen is not None else set()
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#") or line.startswith("//"):
            continue
        parts = line.split()
        token = parts[0]
        attrs = parts[1:]
        # never merge ad / china-specific entries into these bases
        if "@ads" in attrs or "@cn" in attrs:
            continue
        if token.startswith("include:"):
            if depth >= 5:
                continue
            name = token[len("include:"):]
            if name in seen:
                continue
            seen.add(name)
            try:
                yield from parse_v2fly(fetch(V2FLY_BASE + name), depth + 1, seen)
            except Exception as e:
                print(f"  ! v2fly include {name}: {e}", file=sys.stderr)
            continue
        if token.startswith(("keyword:", "regexp:")):
            continue
        if token.startswith("full:"):
            yield token[len("full:"):]
        else:
            yield token


def collect_domains(group, sources):
    found = set()
    for src in sources.get("domains", []):
        url, fmt = src["url"], src["format"]
        print(f"  [{group}] {fmt}: {url}")
        try:
            text = fetch(url)
        except Exception as e:
            print(f"  ! failed: {e}", file=sys.stderr)
            continue
        if fmt == "plain":
            items = parse_plain(text)
        elif fmt == "loon":
            items = parse_loon(text)
        elif fmt == "v2fly":
            items = parse_v2fly(text)
        else:
            print(f"  ! unknown format {fmt}", file=sys.stderr)
            continue
        for item in items:
            d = normalize(item)
            if d:
                found.add(d)

    # local additions
    local = os.path.join(ROOT, "rules", group, "domains.txt")
    if os.path.exists(local):
        for item in parse_plain(open(local, encoding="utf-8").read()):
            d = normalize(item)
            if d:
                found.add(d)

    out = os.path.join(BUILD, f"{group}-domains.txt")
    with open(out, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(sorted(found)) + "\n")
    print(f"  [{group}] domains: {len(found)} -> {out}")


def collect_cidrs(paths, out_path):
    nets = set()
    for path in paths:
        if not path or not os.path.exists(path):
            continue
        for line in open(path, encoding="utf-8"):
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            try:
                net = ipaddress.ip_network(line, strict=False)
            except ValueError:
                continue
            nets.add(str(net))
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(sorted(nets)) + "\n")
    print(f"  cidr: {len(nets)} -> {out_path}")


def main():
    os.makedirs(BUILD, exist_ok=True)
    cfg = json.load(open(os.path.join(ROOT, "sources.json"), encoding="utf-8"))
    print("Merging sources:")
    for group in cfg.keys():
        collect_domains(group, cfg.get(group, {}))

    collect_cidrs(
        [
            os.path.join(ROOT, "rules", "games", "ipcidr.txt"),
            os.path.join(BUILD, "upstream-game-ip.txt"),
        ],
        os.path.join(BUILD, "games-ip.txt"),
    )
    collect_cidrs(
        [os.path.join(ROOT, "rules", "discord", "ipcidr.txt")],
        os.path.join(BUILD, "discord-ip.txt"),
    )
    print("Done.")


if __name__ == "__main__":
    main()
