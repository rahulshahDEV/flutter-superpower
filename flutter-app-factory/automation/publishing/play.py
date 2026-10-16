"""Google Play edits API: plan locally; explicitly authorize every upload/commit."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from urllib.parse import quote

from . import artifacts
from .common import HTTP, Journal, PublishingError, authorize, identifier, run_cli
from .google_auth import token_provider

BASE = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications"
UPLOAD = "https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications"


def metadata(path: Path | None) -> dict:
    if path is None:
        return {}
    content = json.loads(path.read_text())
    if not isinstance(content, dict) or not content:
        raise PublishingError("Store listing JSON must map locales to listing fields")
    for locale, listing in content.items():
        if not isinstance(locale, str) or not locale.replace("-", "").isalnum() or not isinstance(listing, dict):
            raise PublishingError("Invalid store listing locale or fields")
        limits = {"title": 30, "shortDescription": 80, "fullDescription": 4000}
        if set(listing) != set(limits):
            raise PublishingError("Each listing needs title, shortDescription, fullDescription")
        for key, limit in limits.items():
            if not isinstance(listing[key], str) or not listing[key].strip() or len(listing[key]) > limit:
                raise PublishingError(f"Listing {locale}/{key} must contain 1..{limit} characters")
    return content


def notes(path: Path | None, locale: str) -> list:
    if path is None:
        raise PublishingError("Provide --release-notes with reviewed release notes")
    value = path.read_text().strip()
    if not value or len(value) > 500:
        raise PublishingError("Release notes must contain 1..500 characters for the selected locale")
    return [{"language": locale, "text": value}]


def publish(args, http=None) -> dict:
    authorize(args.authorize_upload, args.track == "production", args.approve_production)
    info = artifacts.aab(args.artifact, args.package_id, strict=True)
    listings, release_notes = metadata(args.metadata), notes(args.release_notes, args.locale)
    http = http or HTTP(token_provider())
    identity = {"provider": "google-play", "package_id": args.package_id, "track": args.track,
                "sha256": info["sha256"], "version_code": info["version_code"]}
    with Journal(args.journal, identity).locked() as journal:
        if journal.data.get("phase") == "committed":
            return {"status": "commit_confirmed", "receipt": journal.data, "publicly_live": "unconfirmed"}
        if journal.data.get("phase") in ("create_in_flight", "commit_in_flight"):
            raise PublishingError("Previous edit creation/commit outcome is unknown. Reconcile in Play Console; do not upload again")
        app_url = f"{BASE}/{quote(args.package_id, safe='')}/edits"
        edit = journal.data.get("edit_id")
        if not edit:
            journal.save(phase="create_in_flight")
            edit = http.request("POST", app_url, {})["id"]
            journal.save(edit_id=edit, phase="created")
        edit_url = f"{app_url}/{quote(edit, safe='')}"
        http.request("GET", edit_url)  # Expired/invalid edits fail instead of creating another edit.
        bundles = http.request("GET", f"{edit_url}/bundles").get("bundles", [])
        matches = [b for b in bundles if str(b.get("versionCode")) == info["version_code"]]
        if matches:
            if matches[0].get("sha256", "").lower() != info["sha256"]:
                raise PublishingError("Version code already exists with a different/unverifiable SHA256")
            journal.save(phase="uploaded", version_code=info["version_code"])
        elif journal.data.get("phase") == "upload_in_flight":
            raise PublishingError("Upload outcome is uncertain and bundle is not visible; reconcile before retrying")
        else:
            journal.save(phase="upload_in_flight")
            bundle = http.request("POST", f"{UPLOAD}/{quote(args.package_id, safe='')}/edits/{quote(edit, safe='')}/bundles?uploadType=media", media=args.artifact)
            if str(bundle.get("versionCode")) != info["version_code"] or bundle.get("sha256", "").lower() != info["sha256"]:
                raise PublishingError("Google uploaded bundle response differs from local artifact")
            journal.save(phase="uploaded", version_code=info["version_code"])
        for locale, listing in listings.items():
            http.request("PUT", f"{edit_url}/listings/{quote(locale, safe='')}", listing)
        release = {"name": f"{info['version']} ({info['version_code']})", "versionCodes": [info["version_code"]],
                   "status": args.release_status, "releaseNotes": release_notes}
        track_url = f"{edit_url}/tracks/{quote(args.track, safe='')}"
        current = http.request("GET", track_url)
        if any(r.get("status") in ("inProgress", "halted") for r in current.get("releases", [])):
            raise PublishingError("Track has a staged/halted release; resolve it explicitly before replacing track releases")
        journal.save(phase="track_update_in_flight")
        http.request("PUT", track_url, {"track": args.track, "releases": [release]})
        verified = http.request("GET", track_url)
        if not any(info["version_code"] in [str(v) for v in r.get("versionCodes", [])] for r in verified.get("releases", [])):
            raise PublishingError("Track did not confirm uploaded version code")
        http.request("POST", f"{edit_url}:validate")
        journal.save(phase="commit_in_flight")
        commit = http.request("POST", f"{edit_url}:commit?changesInReviewBehavior=ERROR_IF_IN_REVIEW")
        journal.save(phase="committed", committed_edit_id=commit.get("id", edit), release_status=args.release_status)
        return {"status": "commit_confirmed", "package_id": args.package_id, "track": args.track,
                "version_code": info["version_code"], "publicly_live": "unconfirmed",
                "note": "Review, managed publishing, and track eligibility may still block availability"}


def execute(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("plan", "publish", "status"))
    parser.add_argument("--package-id", required=True)
    parser.add_argument("--artifact", type=Path)
    parser.add_argument("--track", choices=("internal", "alpha", "beta", "production"), default="internal")
    parser.add_argument("--release-status", choices=("draft", "completed"), default="draft")
    parser.add_argument("--release-notes", type=Path)
    parser.add_argument("--locale", default="en-US")
    parser.add_argument("--metadata", type=Path)
    parser.add_argument("--journal", type=Path, default=Path(".factory/releases/google-play.json"))
    parser.add_argument("--authorize-upload", action="store_true")
    parser.add_argument("--approve-production", action="store_true")
    parser.add_argument("--edit-id", help="Read an existing uncommitted edit without creating an edit")
    args = parser.parse_args(argv)
    identifier(args.package_id)
    if args.action == "status":
        if args.edit_id:
            http = HTTP(token_provider())
            url = f"{BASE}/{quote(args.package_id, safe='')}/edits/{quote(args.edit_id, safe='')}"
            return {"edit": http.request("GET", url), "track": http.request("GET", f"{url}/tracks/{args.track}"),
                    "publicly_live": "unconfirmed"}
        if not args.journal.exists():
            raise PublishingError("No local receipt. Provide --edit-id for an existing uncommitted edit")
        receipt = json.loads(args.journal.read_text())
        if receipt.get("identity", {}).get("package_id") != args.package_id or receipt.get("identity", {}).get("track") != args.track:
            raise PublishingError("Receipt target differs from selected package/track")
        return {"status": "local_receipt", "receipt": receipt, "live_store_status": "not_queried"}
    if args.artifact is None:
        raise PublishingError("Provide --artifact PATH.aab")
    if args.action == "publish":
        return publish(args)
    return {"status": "plan_only", "artifact": artifacts.aab(args.artifact, args.package_id),
            "metadata_locales": list(metadata(args.metadata)), "track": args.track,
            "release_status": args.release_status, "external_requests": 0,
            "requirements": ["App exists and initial Play Console setup/upload completed", "Reviewed release notes",
                             "BUNDLETOOL_JAR", "Google credentials", "Explicit upload authorization"]}


def main(argv=None):
    return run_cli(execute, argv)


if __name__ == "__main__":
    raise SystemExit(main())
