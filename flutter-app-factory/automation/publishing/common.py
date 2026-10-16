"""Small HTTP and journal primitives. Never log credentials or HTTP bodies on error."""
from __future__ import annotations

import contextlib
import hashlib
import json
import os
from pathlib import Path
import re
import time
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


class PublishingError(RuntimeError):
    """An actionable publishing failure without sensitive response data."""


def identifier(value: str) -> str:
    if not re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*(?:\.[A-Za-z][A-Za-z0-9_]*){1,}", value):
        raise PublishingError("Expected a reverse-domain application identifier")
    return value


def require_env(name: str) -> str:
    value = os.environ.get(name)
    if not value:
        raise PublishingError(f"Set {name} through your secure environment")
    return value


def digest(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def authorize(write: bool, production: bool = False, approved: bool = False) -> None:
    if not write:
        raise PublishingError("External writes require --authorize-upload (or --authorize-write)")
    if production and not approved:
        raise PublishingError("Production requires explicit user approval and --approve-production")


class HTTP:
    """Bounded retries for reads only; writes are never blindly retried."""

    def __init__(self, token):
        self.token = token

    def request(self, method: str, url: str, body=None, *, media: Path | None = None):
        headers = {"Authorization": f"Bearer {self.token()}", "Accept": "application/json"}
        if media:
            data = media.read_bytes()
            headers["Content-Type"] = "application/octet-stream"
        elif body is not None:
            data = json.dumps(body).encode()
            headers["Content-Type"] = "application/json"
        else:
            data = None
        for attempt in range(3 if method == "GET" else 1):
            try:
                with urlopen(Request(url, data=data, headers=headers, method=method), timeout=180) as response:
                    payload = response.read()
                    return json.loads(payload) if payload else {}
            except HTTPError as error:
                error.close()
                if method == "GET" and error.code in (429, 500, 502, 503, 504) and attempt < 2:
                    time.sleep(2 ** attempt)
                    continue
                raise PublishingError(f"Store API returned HTTP {error.code}; inspect provider logs securely") from None
            except (URLError, TimeoutError, OSError):
                if method == "GET" and attempt < 2:
                    time.sleep(2 ** attempt)
                    continue
                raise PublishingError("Store request interrupted; write outcome may be unknown. Reconcile before retrying") from None


class Journal:
    """Local receipts, atomic writes, and a single-writer lock. Contains no credentials."""

    def __init__(self, path: Path, identity: dict):
        self.path = path
        self.identity = identity
        self.data = {}

    @contextlib.contextmanager
    def locked(self):
        self.path.parent.mkdir(parents=True, exist_ok=True)
        lock = self.path.with_suffix(self.path.suffix + ".lock")
        try:
            fd = os.open(lock, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
        except FileExistsError:
            raise PublishingError("Publishing journal is locked; check for an active process before removing a stale lock") from None
        try:
            os.close(fd)
            if self.path.exists():
                self.data = json.loads(self.path.read_text())
                if self.data.get("identity") != self.identity:
                    raise PublishingError("Journal belongs to a different artifact/target; use a separate journal")
            else:
                self.data = {"identity": self.identity}
            yield self
        finally:
            lock.unlink(missing_ok=True)

    def save(self, **fields):
        self.data.update(fields, updated_at=int(time.time()))
        temporary = self.path.with_suffix(self.path.suffix + ".tmp")
        fd = os.open(temporary, os.O_CREAT | os.O_TRUNC | os.O_WRONLY, 0o600)
        with os.fdopen(fd, "w") as stream:
            json.dump(self.data, stream, indent=2)
            stream.write("\n")
        temporary.replace(self.path)


def run_cli(callback, argv=None):
    try:
        result = callback(argv)
        print(json.dumps(result, indent=2))
        return 0
    except (PublishingError, ValueError, OSError) as error:
        # No raw HTTP/subprocess output, tokens, key material, or environment dump.
        print(json.dumps({"status": "blocked", "error": str(error)}))
        return 1
