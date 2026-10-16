"""Official altool delivery and App Store Connect status/TestFlight integration."""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
from urllib.parse import quote, urlencode

from . import artifacts
from .apple_auth import token_provider
from .common import HTTP, Journal, PublishingError, authorize, identifier, require_env, run_cli

BASE = "https://api.appstoreconnect.apple.com/v1"


def get_app(http, app_id: str, bundle_id: str):
    if not app_id.isdigit():
        raise PublishingError("App Store Connect app ID must be numeric")
    app = http.request("GET", f"{BASE}/apps/{app_id}")["data"]
    if app.get("attributes", {}).get("bundleId") != bundle_id:
        raise PublishingError("App Store Connect app ID belongs to another bundle identifier")
    return app


def status(args, http=None):
    http = http or HTTP(token_provider())
    get_app(http, args.app_id, args.bundle_id)
    query = {"filter[app]": args.app_id, "include": "buildBetaDetail,preReleaseVersion,betaAppReviewSubmission",
             "sort": "-uploadedDate", "limit": "20"}
    if args.build_number:
        query["filter[version]"] = args.build_number
    if args.version:
        query["filter[preReleaseVersion.version]"] = args.version
    response = http.request("GET", f"{BASE}/builds?{urlencode(query)}")
    return {"status": "queried", "builds": response.get("data", []), "included": response.get("included", []),
            "more_results": bool(response.get("links", {}).get("next")),
            "publicly_live": "unconfirmed", "note": "VALID processing alone does not confirm tester availability or App Store release"}


def upload(args, http=None):
    authorize(args.authorize_upload)
    info = artifacts.ipa(args.artifact, args.bundle_id)
    http = http or HTTP(token_provider())
    get_app(http, args.app_id, args.bundle_id)
    identity = {"provider": "app-store-connect", "app_id": args.app_id, "bundle_id": args.bundle_id,
                "sha256": info["sha256"], "version": info["version"], "build": info["build"]}
    with Journal(args.journal, identity).locked() as journal:
        if journal.data.get("phase") == "delivered":
            return {"status": "delivery_previously_confirmed", "receipt": journal.data,
                    "testflight_available": "unconfirmed", "next": "Query status; do not upload this build again"}
        if journal.data.get("phase") == "upload_in_flight":
            raise PublishingError("IPA delivery outcome unknown. Query Apple build status before any retry")
        existing = http.request("GET", f"{BASE}/builds?" + urlencode({"filter[app]": args.app_id,
                                "filter[version]": info["build"], "filter[preReleaseVersion.version]": info["version"]}))
        if existing.get("data"):
            raise PublishingError("This marketing version/build already exists on Apple; query status instead of re-uploading")
        key_id, issuer = require_env("ASC_KEY_ID"), require_env("ASC_ISSUER_ID")
        if not re.fullmatch(r"[A-Za-z0-9]+", key_id):
            raise PublishingError("ASC_KEY_ID has invalid characters")
        key_path = Path(require_env("ASC_PRIVATE_KEY_PATH"))
        if not key_path.is_file():
            raise PublishingError("ASC_PRIVATE_KEY_PATH must point to the private .p8 key")
        with tempfile.TemporaryDirectory(prefix="factory-asc-") as directory:
            key_copy = Path(directory) / f"AuthKey_{key_id}.p8"
            fd = os.open(key_copy, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
            with os.fdopen(fd, "wb") as stream:
                stream.write(key_path.read_bytes())
            environment = {**os.environ, "API_PRIVATE_KEYS_DIR": directory}
            authentication = ["--apiKey", key_id, "--apiIssuer", issuer]
            validate = ["xcrun", "altool", "--validate-app", "-f", str(args.artifact), "-t", "ios", *authentication]
            try:
                result = subprocess.run(validate, capture_output=True, timeout=1800, check=False, env=environment)
                if result.returncode:
                    raise PublishingError("Apple artifact validation failed; inspect Apple delivery logs securely")
                command = ["xcrun", "altool", "--upload-package", str(args.artifact), "-t", "ios",
                           "--apple-id", args.app_id, "--bundle-id", args.bundle_id,
                           "--bundle-short-version-string", info["version"], "--bundle-version", info["build"], *authentication]
                if args.provider_id:
                    command += ["--asc-public-id", args.provider_id]
                journal.save(phase="upload_in_flight")
                result = subprocess.run(command, capture_output=True, timeout=3600, check=False, env=environment)
                if result.returncode:
                    raise PublishingError("Apple delivery failed or was interrupted. Query build status before retrying")
                journal.save(phase="delivered")
            except FileNotFoundError:
                raise PublishingError("Install Xcode and select its developer directory; xcrun altool is required") from None
            except subprocess.TimeoutExpired:
                raise PublishingError("Apple validation/delivery timed out. Query build status before retrying an upload") from None
        return {"status": "delivery_confirmed", "version": info["version"], "build": info["build"],
                "processing": "pending_confirmation", "testflight_available": "unconfirmed", "publicly_live": False}


def distribute(args, http=None):
    authorize(args.authorize_write)
    if not args.build_id or not args.group_id:
        raise PublishingError("Provide --build-id and --group-id for an existing internal TestFlight group")
    http = http or HTTP(token_provider())
    get_app(http, args.app_id, args.bundle_id)
    build_url = f"{BASE}/builds/{quote(args.build_id, safe='')}"
    app = http.request("GET", f"{build_url}/app")["data"]
    if app["id"] != args.app_id:
        raise PublishingError("Build belongs to another app")
    build = http.request("GET", build_url)["data"]
    if build.get("attributes", {}).get("processingState") != "VALID" or build.get("attributes", {}).get("expired"):
        raise PublishingError("Build is not VALID; processing or export compliance must finish first")
    group_url = f"{BASE}/betaGroups/{quote(args.group_id, safe='')}"
    group = http.request("GET", group_url)["data"]
    if not group.get("attributes", {}).get("isInternalGroup"):
        raise PublishingError("Only internal TestFlight groups are automated; external beta review requires a separate reviewed submission")
    group_app = http.request("GET", f"{group_url}/app")["data"]
    if group_app["id"] != args.app_id:
        raise PublishingError("TestFlight group belongs to another app")
    relation_url = f"{build_url}/relationships/betaGroups"
    relation = http.request("GET", relation_url)
    if not any(item["id"] == args.group_id for item in relation.get("data", [])):
        http.request("POST", f"{group_url}/relationships/builds", {"data": [{"type": "builds", "id": args.build_id}]})
    relation = http.request("GET", relation_url)
    if not any(item["id"] == args.group_id for item in relation.get("data", [])):
        raise PublishingError("Apple did not confirm the TestFlight group relationship")
    detail = http.request("GET", f"{build_url}/buildBetaDetail")
    state = detail.get("data", {}).get("attributes", {}).get("internalBuildState")
    return {"status": "group_assignment_confirmed", "build_id": args.build_id, "group_id": args.group_id,
            "internal_build_state": state, "testflight_available": state == "IN_BETA_TESTING", "publicly_live": False}


def execute(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("plan", "upload", "status", "releases", "testflight"))
    parser.add_argument("--bundle-id", required=True)
    parser.add_argument("--app-id", required=True, help="Numeric App Store Connect app ID")
    parser.add_argument("--artifact", type=Path)
    parser.add_argument("--version")
    parser.add_argument("--build-number")
    parser.add_argument("--build-id")
    parser.add_argument("--group-id")
    parser.add_argument("--provider-id")
    parser.add_argument("--journal", type=Path, default=Path(".factory/releases/app-store-connect.json"))
    parser.add_argument("--authorize-upload", action="store_true")
    parser.add_argument("--authorize-write", action="store_true")
    args = parser.parse_args(argv)
    identifier(args.bundle_id)
    if not args.app_id.isdigit():
        raise PublishingError("App Store Connect app ID must be numeric")
    if args.action == "status":
        return status(args)
    if args.action == "releases":
        http = HTTP(token_provider())
        get_app(http, args.app_id, args.bundle_id)
        return http.request("GET", f"{BASE}/apps/{args.app_id}/appStoreVersions?limit=200")
    if args.action == "testflight":
        return distribute(args)
    if args.artifact is None:
        raise PublishingError("Provide --artifact PATH.ipa")
    if args.action == "upload":
        return upload(args)
    return {"status": "plan_only", "artifact": artifacts.ipa(args.artifact, args.bundle_id), "external_requests": 0,
            "requirements": ["Existing App Store Connect app and agreements", "Apple distribution signing",
                             "Team API key environment", "Xcode altool", "Explicit upload authorization"],
            "production_submission": "Requires explicit approval and Apple's review; this uploader does not submit production"}


def main(argv=None):
    return run_cli(execute, argv)


if __name__ == "__main__":
    raise SystemExit(main())
