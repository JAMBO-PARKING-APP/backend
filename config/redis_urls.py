"""Helpers for Redis URLs (split logical DBs per workload)."""
from __future__ import annotations

from urllib.parse import urlparse, urlunparse


def redis_url_for_database(redis_url: str, db: int) -> str:
    """
    Return a Redis URL pointing at the given database index (0–15).

    Preserves scheme (redis/rediss), auth, host, port, and query string.
    """
    if not redis_url:
        return redis_url
    p = urlparse(redis_url)
    if p.scheme not in ('redis', 'rediss'):
        return redis_url
    return urlunparse((p.scheme, p.netloc, f'/{db}', '', p.query, p.fragment))
