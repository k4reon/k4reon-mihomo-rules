#!/usr/bin/env python3
"""Merge public rule sources + local k4reon additions into build/*.

sources.json schema:
  "<group>": {
    "domains": [ {"url": "...", "format": "plain|loon|v2fly|mrs"} ],
    "ipcidr":  [ {"url": "...", "format": "plain|loon|mrs"} ]
  }

Formats:
  plain  - one domain/CIDR per line
  loon   - DOMAIN, DOMAIN-SUFFIX, IP-CIDR, ...
  v2fly  - v2fly domain lists (include:/full:/keyword:)
  mrs    - mihomo binary rule-set; converted via $MIHOMO_BIN
"""
import hashlib
import ipaddress
import json
import os
import re
import subprocess
import sys
import time
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BUILD = os.path.join(ROOT, "build")
CACHE = os.path.join(BUILD, "cache")
UA = {"User-Agent": "k4reon-mrs-build/1.1"}
V2FLY_BASE = "https://raw.githubusercontent.com/v2fly/domain-list-community/master/data/"
DOMAIN_RE = re.compile(r"^[a-z0-9]([a-z0-9_-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9_-]*[a-z0-9])?)+$")
MIHOMO = os.environ.get("MIHOMO_BIN", "")


def load_denylist():
    path = os.path.join(ROOT, "rules", "denylist.txt")
    if not os.path.exists(path):
        return []
    return [l.strip().lower() for l in open(path, encoding="utf-8")
            if l.strip() and not l.strip().startswith("#")]


DENY = load_denylist()


def fetch_bytes(url):
    key = hashlib.sha1(url.encode()).hexdigest()
    path = os.path.join(CACHE, key)
    if os.path.exists(path) and time.time() - os.path.getmtime(path) < 6 * 3600:
        return open(path, "rb").read()
    last = None
    for attempt in range(3):
        try:
            req = urllib.request.Request(url, headers=UA)
            with urllib.request.urlopen(req, timeout=60) as r:
                data = r.read()
            open(path, "wb").write(data)
            return data
        except Exception as e:
            last = e
            if attempt < 2:
                time.sleep(1 + attempt)
    raise last


def fetch_text(url):
    return fetch_bytes(url).decode("utf-8", "replace")


def normalize_domain(value, use_deny=False):
    d = value.strip().lower().rstrip(".")
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
        return None  # an IP, not a domain
    except ValueError:
        pass
    if use_deny and any(x in d for x in DENY):
        return None
    return d


def normalize_cidr(value):
    try:
        net = ipaddress.ip_network(value.strip(), strict=False)
    except ValueError:
        return None
    if net.version == 6:
        return None  # ipv6: false in router config
    return str(net)


def parse_plain(text, kind):
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#") or line.startswith("//"):
            continue
        yield line


def parse_loon(text, kind):
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split(",")
        head = parts[0]
        if kind == "domain":
            if head in ("DOMAIN-SUFFIX", "DOMAIN") and len(parts) > 1:
                yield parts[1]
            elif head == "DOMAIN-WILDCARD" and len(parts) > 1:
                yield parts[1].lstrip("*.")
        else:
            if head == "IP-CIDR" and len(parts) > 1:
                yield parts[1]
            elif head == "IP-CIDR6":
                continue


def parse_v2fly(text, depth=0, seen=None):
    seen = seen if seen is not None else set()
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#") or line.startswith("//"):
            continue
        parts = line.split()
        token, attrs = parts[0], parts[1:]
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
                yield from parse_v2fly(fetch_text(V2FLY_BASE + name), depth + 1, seen)
            except Exception as e:
                print(f"  ! v2fly include {name}: {e}", file=sys.stderr)
            continue
        if token.startswith(("keyword:", "regexp:")):
            continue
        if token.startswith("full:"):
            yield token[len("full:"):]
        else:
            yield token


def mrs_to_text(url, behavior):
    if not MIHOMO:
        raise RuntimeError("MIHOMO_BIN is not set; needed for mrs sources")
    key = hashlib.sha1(f"{behavior}:{url}".encode()).hexdigest()
    src = os.path.join(CACHE, key + ".mrs")
    dst = os.path.join(CACHE, key + ".txt")
    if not os.path.exists(dst):
        if not os.path.exists(src):
            open(src, "wb").write(fetch_bytes(url))
        subprocess.run([MIHOMO, "convert-ruleset", behavior, "mrs", src, dst],
                       check=True, capture_output=True)
    return open(dst, encoding="utf-8").read()


def collect(group, cfg, kind):
    found = set()
    sources = cfg.get("domains" if kind == "domain" else "ipcidr", [])
    for src in sources:
        url, fmt = src["url"], src["format"]
        print(f"  [{group}/{kind}] {fmt}: {url}")
        try:
            if fmt == "mrs":
                text = mrs_to_text(url, kind)
                items = parse_plain(text, kind)
            else:
                text = fetch_text(url)
                if fmt == "plain":
                    items = parse_plain(text, kind)
                elif fmt == "loon":
                    items = parse_loon(text, kind)
                elif fmt == "v2fly":
                    items = parse_v2fly(text)
                else:
                    print(f"  ! unknown format {fmt}", file=sys.stderr)
                    continue
            for item in items:
                val = normalize_domain(item, use_deny=(group == "games")) if kind == "domain" else normalize_cidr(item)
                if val:
                    found.add(val)
        except Exception as e:
            print(f"  ! failed {url}: {e}", file=sys.stderr)

    local = os.path.join(ROOT, "rules", group, "domains.txt" if kind == "domain" else "ipcidr.txt")
    if os.path.exists(local):
        for item in parse_plain(open(local, encoding="utf-8").read(), kind):
            val = normalize_domain(item, use_deny=False) if kind == "domain" else normalize_cidr(item)
            if val:
                found.add(val)

    if not found:
        return 0
    out = os.path.join(BUILD, f"{group}-domains.txt" if kind == "domain" else f"{group}-ip.txt")
    lines = sorted(found)
    if kind == "domain":
        # mihomo domain mrs: '+.' means suffix, plain means exact.
        # All merged lists are category suffixes, so make them suffix rules.
        lines = ["+." + x for x in lines]
    with open(out, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")
    print(f"  [{group}] {kind}: {len(found)} -> {os.path.basename(out)}")
    return len(found)


def main():
    os.makedirs(CACHE, exist_ok=True)
    cfg = json.load(open(os.path.join(ROOT, "sources.json"), encoding="utf-8"))
    print("Merging sources:")
    for group, groupsrc in cfg.items():
        collect(group, groupsrc, "domain")
        collect(group, groupsrc, "ipcidr")
    # custom group has only local classical rules; no merge
    print("Done.")


if __name__ == "__main__":
    main()
