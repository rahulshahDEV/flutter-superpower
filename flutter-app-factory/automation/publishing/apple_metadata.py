"""Validate or apply reviewed localized App Store version metadata through ASC."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from urllib.parse import quote, urlparse

from .apple import BASE, get_app
from .apple_auth import token_provider
from .common import HTTP, PublishingError, authorize, identifier, run_cli

LIMITS = {"description": 4000, "keywords": 100, "promotionalText": 170, "whatsNew": 4000}
FIELDS = set(LIMITS) | {"supportUrl", "marketingUrl"}


def metadata(path: Path) -> dict:
    content = json.loads(path.read_text())
    if not isinstance(content, dict) or not content:
        raise PublishingError("Metadata JSON must map locales to version listing fields")
    for locale, fields in content.items():
        if not isinstance(locale, str) or not locale.replace("-", "").isalnum() or not isinstance(fields, dict):
            raise PublishingError("Invalid metadata locale or fields")
        if not fields or set(fields) - FIELDS:
            raise PublishingError("Unsupported metadata field; app name/subtitle/privacy URL belong to app info, managed separately")
        for name, value in fields.items():
            if not isinstance(value, str):
                raise PublishingError(f"Metadata {locale}/{name} must be text")
            if name in LIMITS:
                size = len(value.encode("utf-8")) if name == "keywords" else len(value)
                if size > LIMITS[name]:
                    unit = "UTF-8 bytes" if name == "keywords" else "characters"
                    raise PublishingError(f"Metadata {locale}/{name} exceeds {LIMITS[name]} {unit}")
            else:
                url = urlparse(value)
                if url.scheme != "https" or not url.netloc or url.username or url.password:
                    raise PublishingError("Store support/marketing URLs must be public HTTPS URLs without credentials")
    return content


def apply(args, http=None):
    authorize(args.authorize_write)
    content = metadata(args.metadata)
    if not args.version_id:
        raise PublishingError("Provide --version-id for the selected existing App Store version")
    http = http or HTTP(token_provider())
    get_app(http, args.app_id, args.bundle_id)
    version_url = f"{BASE}/appStoreVersions/{quote(args.version_id, safe='')}"
    version = http.request("GET", f"{version_url}?include=app")["data"]
    if version.get("relationships", {}).get("app", {}).get("data", {}).get("id") != args.app_id:
        raise PublishingError("App Store version belongs to another app or app relationship is unverified")
    response = http.request("GET", f"{version_url}/appStoreVersionLocalizations?limit=200")
    if response.get("links", {}).get("next"):
        raise PublishingError("Localization pagination needs reconciliation; refusing partial metadata update")
    existing = {item["attributes"]["locale"]: item["id"] for item in response.get("data", [])}
    updated = []
    for locale, fields in content.items():
        if locale in existing:
            resource_id = existing[locale]
            url = f"{BASE}/appStoreVersionLocalizations/{quote(resource_id, safe='')}"
            http.request("PATCH", url, {"data": {"type": "appStoreVersionLocalizations", "id": resource_id,
                                                 "attributes": fields}})
        else:
            created = http.request("POST", f"{BASE}/appStoreVersionLocalizations", {"data": {
                "type": "appStoreVersionLocalizations", "attributes": {"locale": locale, **fields},
                "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": args.version_id}}}}})
            resource_id = created["data"]["id"]
            url = f"{BASE}/appStoreVersionLocalizations/{quote(resource_id, safe='')}"
        confirmed = http.request("GET", url)["data"]["attributes"]
        if any(confirmed.get(key) != value for key, value in fields.items()):
            raise PublishingError("Apple metadata read-back differs from submitted values")
        updated.append(locale)
    return {"status": "metadata_confirmed", "locales": updated, "submitted_for_review": False}


def execute(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("plan", "apply"))
    parser.add_argument("--metadata", type=Path, required=True)
    parser.add_argument("--bundle-id", required=True)
    parser.add_argument("--app-id", required=True)
    parser.add_argument("--version-id")
    parser.add_argument("--authorize-write", action="store_true")
    args = parser.parse_args(argv)
    identifier(args.bundle_id)
    if not args.app_id.isdigit():
        raise PublishingError("App Store Connect app ID must be numeric")
    if args.action == "apply":
        return apply(args)
    return {"status": "plan_only", "locales": list(metadata(args.metadata)), "external_requests": 0,
            "manual_requirements": ["App name/subtitle/privacy URL in app info", "Screenshots, privacy disclosures, age rating",
                                    "App Review contact and credentials when needed", "Explicit approval before production submission"]}


def main(argv=None):
    return run_cli(execute, argv)


if __name__ == "__main__":
    raise SystemExit(main())
