"""Generate explicit Codemagic workflows and call its official build APIs.

Generation is local. Calling trigger() starts a potentially billable remote build;
the caller must obtain authorization first. No production store publishing is
generated. API responses are reduced to a safe allowlist before returning them.
"""

from __future__ import annotations

import json
from pathlib import Path
import re
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import HTTPRedirectHandler, Request, build_opener

import yaml


_IDENTIFIER = re.compile(r"[a-z][a-z0-9]*(?:[._][a-z][a-z0-9_]*)+\Z")
_SLUG = re.compile(r"[a-z][a-z0-9_]*\Z")
_REFERENCE = re.compile(r"[A-Za-z0-9_. -]+\Z")
_API_ID = re.compile(r"[A-Za-z0-9_-]+\Z")
_WORKFLOW = re.compile(
    r"[a-z][a-z0-9_]*-(?:(?:dev|prod)-(?:android|ios)-build|"
    r"prod-android-internal|prod-ios-testflight)\Z"
)
_TERMINAL = {"finished", "failed", "canceled", "timeout", "skipped"}


def _reference(value: Any, label: str) -> str:
    if not isinstance(value, str) or not _REFERENCE.fullmatch(value):
        raise ValueError(f"Invalid {label}; use a Codemagic reference name")
    return value


def workflow_id(slug: str, flavor: str, platform: str, publish: bool = False) -> str:
    """Return a generated YAML key; prod flavor alone never enables publishing."""
    if not _SLUG.fullmatch(slug) or flavor not in {"dev", "prod"}:
        raise ValueError("Invalid app slug or flavor")
    if platform not in {"android", "ios"} or (publish and flavor != "prod"):
        raise ValueError("Testing distribution requires prod and a supported platform")
    suffix = ("internal" if platform == "android" else "testflight") if publish else "build"
    return f"{slug}-{flavor}-{platform}-{suffix}"


def _step(name: str, script: str) -> dict[str, str]:
    return {"name": name, "script": "set -euo pipefail\n" + script}


def _workflow(config: dict, flavor: str, platform: str, publish: bool) -> dict:
    slug = config["app"]["slug"]
    app_dir = f"apps/{slug}"
    deployment = config["deployment"]
    selected = config["flavors"][flavor]
    version = str(config["app"]["version"])
    build = config["app"]["build_number"]
    if not re.fullmatch(r"\d+\.\d+\.\d+(?:-[A-Za-z0-9.-]+)?", version):
        raise ValueError(f"Invalid version for {slug}")
    if isinstance(build, bool) or not isinstance(build, int) or build < 1:
        raise ValueError(f"Invalid build number for {slug}")
    group = deployment.get("environment_groups", {}).get(flavor)
    if not group:
        group = deployment.get("environment_group", f"{slug}_prod") if flavor == "prod" else f"{slug}_dev"
    environment: dict[str, Any] = {
        "flutter": "stable",
        "groups": [_reference(group, "environment group")],
        "vars": {"APP_SLUG": slug, "APP_FLAVOR": flavor},
    }
    scripts = [
        _step("Install automation dependencies", "python3 -m pip install -r automation/requirements.txt"),
        _step("Prepare app and public runtime configuration", f"python3 automation/scripts/factory.py ci-prepare {slug} --flavor {flavor} --platform {platform}"),
        _step("Resolve Flutter dependencies", f"cd {app_dir}\nflutter pub get"),
        _step("Validate app", f"python3 automation/scripts/factory.py validate {slug}" + (f" --release --platform {platform}" if flavor == "prod" else "")),
        _step("Analyze and run app and shared package tests", f"python3 automation/scripts/factory.py test {slug}"),
    ]
    workflow: dict[str, Any] = {
        "name": f"{config['app']['name']} {flavor} {platform}" + (" testing distribution" if publish else " build"),
        "instance_type": "mac_mini_m2",
        "max_build_duration": 60,
        "environment": environment,
        # Entries are selected manually or by API. Add webhook events explicitly.
        "when": {"changeset": {"includes": [f"{app_dir}/", "packages/", "automation/"]}},
        "scripts": scripts,
    }
    flags = f"--flavor {flavor} --target lib/main_{flavor}.dart --dart-define-from-file=config/{flavor}.json --build-name={version} --build-number={build}"
    if platform == "android":
        if flavor == "prod":
            environment["android_signing"] = [_reference(config["android"]["signing_reference"], "Android signing reference")]
            scripts.append(_step("Require release signing secrets", 'for key in CM_KEYSTORE_PATH CM_KEYSTORE_PASSWORD CM_KEY_ALIAS CM_KEY_PASSWORD; do\n  test -n "${!key:-}" || { echo "Missing signing variable: $key" >&2; exit 1; }\ndone'))
            command, artifact = "appbundle --release", f"{app_dir}/build/app/outputs/bundle/**/*.aab"
        else:
            command, artifact = "apk --debug", f"{app_dir}/build/app/outputs/flutter-apk/*.apk"
        scripts.append(_step("Build Android", f"cd {app_dir}\nflutter build {command} {flags}"))
    else:
        environment.update({"xcode": "latest", "cocoapods": "default"})
        if flavor == "prod":
            bundle = selected["ios_bundle_id"]
            if not _IDENTIFIER.fullmatch(bundle):
                raise ValueError(f"Invalid iOS bundle identifier for {slug}")
            environment["ios_signing"] = {"distribution_type": "app_store", "bundle_identifier": bundle}
            scripts.append(_step("Apply uploaded signing profiles", f"cd {app_dir}\nxcode-project use-profiles"))
            command = 'ipa --release --export-options-plist="$HOME/export_options.plist"'
            artifact = f"{app_dir}/build/ios/ipa/*.ipa"
        else:
            command, artifact = "ios --simulator --debug", f"{app_dir}/build/ios/iphonesimulator/*.app"
        scripts.append(_step("Build iOS", f"cd {app_dir}\nflutter build {command} {flags}"))
    workflow["artifacts"] = [artifact, f"{app_dir}/build/**/mapping.txt", "/tmp/xcodebuild_logs/*.log"]
    publishing: dict[str, Any] = {}
    recipients = deployment.get("notification_emails", [])
    if recipients:
        if not isinstance(recipients, list) or any(not isinstance(item, str) or not re.fullmatch(r"[^\s@]+@[^\s@]+\.[^\s@]+", item) for item in recipients):
            raise ValueError("notification_emails must contain email addresses")
        publishing["email"] = {"recipients": recipients, "notify": {"success": True, "failure": True}}
    if publish and platform == "android":
        variable = deployment.get("play_credentials_variable", "GCLOUD_SERVICE_ACCOUNT_CREDENTIALS")
        if not re.fullmatch(r"[A-Z][A-Z0-9_]*", variable):
            raise ValueError("Invalid Play credential environment variable name")
        scripts.append(_step("Require Play API credentials", f'test -n "${{{variable}:-}}" || {{ echo "Missing Play API credentials" >&2; exit 1; }}'))
        publishing["google_play"] = {"credentials": f"${variable}", "track": "internal"}
    if publish and platform == "ios":
        integration = _reference(deployment["app_store_connect_integration"], "App Store Connect integration")
        workflow["integrations"] = {"app_store_connect": integration}
        publishing["app_store_connect"] = {"auth": "integration", "submit_to_testflight": True, "submit_to_app_store": False}
        beta_groups = deployment.get("testflight_groups", [])
        if beta_groups:
            publishing["app_store_connect"]["beta_groups"] = [_reference(item, "TestFlight group") for item in beta_groups]
    if publishing:
        workflow["publishing"] = publishing
    return workflow


def generate(root: Path) -> Path:
    """Regenerate only factory-owned YAML; refuse to overwrite handwritten CI."""
    root = Path(root).resolve()
    workflows = {}
    for file in sorted((root / "apps").glob("*/app.yaml")):
        config = yaml.safe_load(file.read_text())
        slug = config["app"]["slug"]
        if not isinstance(slug, str) or not _SLUG.fullmatch(slug) or slug != file.parent.name:
            raise ValueError(f"App slug must match its directory: {file.parent.name}")
        for flavor in ("dev", "prod"):
            if flavor not in config["flavors"]:
                raise ValueError(f"Missing {flavor} flavor for {slug}")
            for platform in ("android", "ios"):
                if config["platforms"].get(platform, False):
                    for publish in ((False, True) if flavor == "prod" else (False,)):
                        workflows[workflow_id(slug, flavor, platform, publish)] = _workflow(config, flavor, platform, publish)
    if not workflows:
        raise ValueError("No configured apps; create an app before generating CI")
    target = root / "codemagic.yaml"
    marker = "# Generated by App Factory; edit app.yaml and regenerate.\n"
    if target.exists() and not target.read_text().startswith(marker):
        raise ValueError("Refusing to overwrite handwritten codemagic.yaml; merge or migrate it explicitly")
    content = marker + "# yaml-language-server: $schema=https://codemagic.io/codemagic-schema.json\n" + yaml.safe_dump({"workflows": workflows}, sort_keys=False, width=120)
    if not target.exists() or target.read_text() != content:
        target.write_text(content)
    return target


class _NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise ValueError("Codemagic API redirect refused to protect authentication")


def _request(token: str, url: str, payload: dict | None = None) -> dict:
    if not token or "\n" in token or "\r" in token:
        raise ValueError("Set a valid Codemagic API token in the environment")
    request = Request(url, data=json.dumps(payload).encode() if payload is not None else None, headers={"x-auth-token": token, "Content-Type": "application/json"}, method="POST" if payload is not None else "GET")
    try:
        with build_opener(_NoRedirect()).open(request, timeout=30) as response:
            raw = response.read(10_000_001)
            if len(raw) > 10_000_000:
                raise ValueError("Response exceeds size limit")
            data = json.loads(raw)
    except HTTPError as error:
        # API bodies can echo credentials; never include them in errors or logs.
        code = error.code
        error.close()
        raise RuntimeError(f"Codemagic API returned HTTP {code}; inspect the provider dashboard") from None
    except (URLError, TimeoutError, OSError):
        raise RuntimeError("Codemagic API request failed; check network and provider status") from None
    except (ValueError, UnicodeDecodeError):
        raise RuntimeError("Codemagic API returned an invalid response") from None
    if not isinstance(data, dict):
        raise RuntimeError("Codemagic API returned an unexpected response")
    return data


def trigger(token: str, application_id: str, workflow_id: str, branch: str) -> dict:
    """Start an authorized build; no retries, to avoid duplicate paid builds."""
    if not _API_ID.fullmatch(application_id) or "REPLACE" in application_id:
        raise ValueError("Configure a valid Codemagic application ID")
    if not _WORKFLOW.fullmatch(workflow_id):
        raise ValueError("Only factory build/internal/TestFlight workflows may be triggered")
    if not branch or len(branch) > 200 or any(ord(char) < 32 for char in branch):
        raise ValueError("Configure a valid Git branch")
    data = _request(token, "https://api.codemagic.io/builds", {"appId": application_id, "workflowId": workflow_id, "branch": branch})
    build_id = data.get("buildId")
    if not isinstance(build_id, str) or not _API_ID.fullmatch(build_id):
        raise RuntimeError("Codemagic did not confirm a build ID; inspect dashboard before retrying")
    return {"build_id": build_id, "workflow_id": workflow_id, "status": "requested", "url": f"https://codemagic.io/app/{application_id}/build/{build_id}", "deployment_confirmed": False}


def status(token: str, build_id: str) -> dict:
    """Read build status; finished does not confirm asynchronous store processing."""
    if not _API_ID.fullmatch(build_id):
        raise ValueError("Invalid build ID")
    data = _request(token, f"https://codemagic.io/api/v3/builds/{build_id}")
    build = data.get("data", {})
    value = build.get("status") if isinstance(build, dict) else None
    known = _TERMINAL | {"initializing", "queued", "preparing", "fetching", "testing", "building", "publishing", "finishing"}
    if value not in known:
        raise RuntimeError("Codemagic returned an unknown build status; inspect dashboard")
    return {"build_id": build_id, "status": value, "terminal": value in _TERMINAL, "build_succeeded": value == "finished", "deployment_confirmed": False}
