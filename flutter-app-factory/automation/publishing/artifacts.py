"""Verify artifact contents before any external upload. No ZIP extraction needed."""
from __future__ import annotations

import os
from pathlib import Path
import plistlib
import re
import subprocess
import zipfile

from .common import PublishingError, digest, identifier


def _archive(path: Path, suffix: str):
    if path.suffix.lower() != suffix or not path.is_file():
        raise PublishingError(f"Expected an existing {suffix} artifact")
    try:
        archive = zipfile.ZipFile(path)
        if archive.testzip() is not None:
            raise PublishingError("Artifact ZIP integrity check failed")
        return archive
    except zipfile.BadZipFile:
        raise PublishingError("Artifact is not a valid ZIP archive") from None


def ipa(path: Path, bundle_id: str) -> dict:
    identifier(bundle_id)
    with _archive(path, ".ipa") as archive:
        candidates = [n for n in archive.namelist() if re.fullmatch(r"Payload/[^/]+\.app/Info\.plist", n)]
        if len(candidates) != 1:
            raise PublishingError("IPA must contain exactly one primary app Info.plist")
        try:
            info = plistlib.loads(archive.read(candidates[0]))
        except (plistlib.InvalidFileException, ValueError):
            raise PublishingError("IPA Info.plist is invalid") from None
        if info.get("CFBundleIdentifier") != bundle_id:
            raise PublishingError("IPA bundle identifier differs from selected app/flavor")
        version, build = info.get("CFBundleShortVersionString"), info.get("CFBundleVersion")
        if not isinstance(version, str) or not re.fullmatch(r"\d+\.\d+(?:\.\d+)?", version):
            raise PublishingError("IPA marketing version is missing or invalid")
        if not isinstance(build, str) or not re.fullmatch(r"\d+(?:\.\d+){0,2}", build):
            raise PublishingError("IPA build number is missing or invalid")
        root = candidates[0].removesuffix("Info.plist")
        if root + "_CodeSignature/CodeResources" not in archive.namelist():
            raise PublishingError("IPA has no primary app code signature resources")
    return {"sha256": digest(path), "bundle_id": bundle_id, "version": version, "build": build,
            "signature": "present; Apple online validation still required"}


def aab(path: Path, package_id: str, *, strict: bool = False) -> dict:
    identifier(package_id)
    with _archive(path, ".aab") as archive:
        names = archive.namelist()
        if "BundleConfig.pb" not in names or "base/manifest/AndroidManifest.xml" not in names:
            raise PublishingError("AAB lacks BundleConfig.pb or base manifest")
        signed = any(n.startswith("META-INF/") and n.upper().endswith((".RSA", ".EC", ".DSA")) for n in names)
        if not signed:
            raise PublishingError("AAB has no JAR signing certificate")
    result = {"sha256": digest(path), "package_id": package_id, "manifest_verified": False}
    jar = os.environ.get("BUNDLETOOL_JAR")
    if not jar:
        if strict:
            raise PublishingError("Set BUNDLETOOL_JAR to verify the AAB package/version before upload")
        return result
    if not Path(jar).is_file():
        raise PublishingError("BUNDLETOOL_JAR does not point to a file")
    try:
        values = {}
        for key, xpath in (("package", "/manifest/@package"), ("version_code", "/manifest/@android:versionCode"),
                           ("version", "/manifest/@android:versionName")):
            command = ["java", "-jar", jar, "dump", "manifest", f"--bundle={path}", f"--xpath={xpath}"]
            proc = subprocess.run(command, capture_output=True, text=True, timeout=120, check=False)
            if proc.returncode:
                raise PublishingError("bundletool could not read the AAB manifest")
            values[key] = proc.stdout.strip()
        if values["package"] != package_id:
            raise PublishingError("AAB package differs from selected app/flavor")
        if not values["version_code"].isdigit() or int(values["version_code"]) < 1:
            raise PublishingError("AAB versionCode must be a positive integer")
        if not re.fullmatch(r"\d+\.\d+\.\d+(?:[-+][A-Za-z0-9.-]+)?", values["version"]):
            raise PublishingError("AAB versionName must use the factory's major.minor.patch version format")
        signature = subprocess.run(["jarsigner", "-verify", str(path)], capture_output=True,
                                   text=True, timeout=120, check=False, env={**os.environ, "LC_ALL": "C"})
        if signature.returncode or "jar verified" not in signature.stdout.lower():
            raise PublishingError("AAB JAR signature verification failed")
        result.update(values, manifest_verified=True)
    except (FileNotFoundError, subprocess.TimeoutExpired):
        raise PublishingError("Java, jarsigner, and bundletool must be available for AAB validation") from None
    return result
