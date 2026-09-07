#!/usr/bin/env python3
"""Build an authenticated HTTPS git URL for private source checkout."""

from __future__ import annotations

import os
import sys
from urllib.parse import quote, urlsplit, urlunsplit


def main() -> int:
    raw = os.environ.get("SOURCE_REPO_URL", "").strip()
    token = os.environ.get("SOURCE_REPO_TOKEN", "").strip()
    if not raw or not token:
        print("SOURCE_REPO_URL and SOURCE_REPO_TOKEN are required", file=sys.stderr)
        return 1

    parts = urlsplit(raw)
    if parts.scheme not in ("http", "https") or not parts.netloc or not parts.path:
        print("SOURCE_REPO_URL must be an https git URL", file=sys.stderr)
        return 1

    host = parts.netloc.lower()
    # Gitee rejects GitHub's x-access-token username ("The token username invalid").
    user = "oauth2" if host.endswith("gitee.com") else "x-access-token"
    netloc = f"{user}:{quote(token, safe='')}@{parts.netloc}"
    print(urlunsplit((parts.scheme, netloc, parts.path, "", "")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
