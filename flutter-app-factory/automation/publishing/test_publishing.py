"""Offline contract tests; no credentials, network, store writes, or paid builds."""
from argparse import Namespace
import base64
import io
import json
import os
from pathlib import Path
import plistlib
import subprocess
import tempfile
import unittest
from unittest.mock import Mock, patch
from urllib.error import HTTPError, URLError
import zipfile

from automation.publishing import apple, apple_auth, apple_metadata, artifacts, play
from automation.publishing.common import HTTP, Journal, PublishingError, identifier


class SequenceHTTP:
    def __init__(self, sequence):
        self.sequence = list(sequence)
        self.calls = []

    def request(self, method, url, body=None, **kwargs):
        self.calls.append((method, url, body, kwargs))
        if not self.sequence:
            raise AssertionError("Unexpected HTTP request")
        result = self.sequence.pop(0)
        if isinstance(result, Exception):
            raise result
        return result


class PublishingTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.ipa = self.root / "app.ipa"
        with zipfile.ZipFile(self.ipa, "w") as archive:
            archive.writestr("Payload/Runner.app/Info.plist", plistlib.dumps({
                "CFBundleIdentifier": "org.example.app", "CFBundleShortVersionString": "1.2.0", "CFBundleVersion": "12"}))
            archive.writestr("Payload/Runner.app/_CodeSignature/CodeResources", b"fixture")
        self.aab = self.root / "app.aab"
        with zipfile.ZipFile(self.aab, "w") as archive:
            archive.writestr("BundleConfig.pb", b"fixture")
            archive.writestr("base/manifest/AndroidManifest.xml", b"fixture")
            archive.writestr("META-INF/APP.RSA", b"fixture")
        self.notes = self.root / "notes.txt"
        self.notes.write_text("Improves startup reliability.")
        self.info = {"sha256": "abc", "version": "1.2.0", "version_code": "12", "manifest_verified": True}
        self.play_args = Namespace(authorize_upload=True, approve_production=False, artifact=self.aab,
            package_id="org.example.app", track="internal", release_status="completed", release_notes=self.notes,
            metadata=None, locale="en-US", journal=self.root / "play.json")
        self.apple_args = Namespace(authorize_upload=True, artifact=self.ipa, app_id="123", bundle_id="org.example.app",
            journal=self.root / "apple.json", provider_id=None, authorize_write=True, build_id="build-1", group_id="group-1")

    def tearDown(self):
        self.temporary.cleanup()

    def test_reverse_domain_validation(self):
        for value in ("app", "../example.app", "org.example/a", "org..app"):
            with self.assertRaises(PublishingError):
                identifier(value)

    def test_ipa_bundle_verified(self):
        self.assertEqual(artifacts.ipa(self.ipa, "org.example.app")["build"], "12")
        with self.assertRaisesRegex(PublishingError, "bundle identifier"):
            artifacts.ipa(self.ipa, "org.other.app")

    def test_unsigned_ipa_rejected(self):
        path = self.root / "unsigned.ipa"
        with zipfile.ZipFile(path, "w") as archive:
            archive.writestr("Payload/App.app/Info.plist", plistlib.dumps({"CFBundleIdentifier": "org.example.app",
                "CFBundleShortVersionString": "1.0.0", "CFBundleVersion": "1"}))
        with self.assertRaisesRegex(PublishingError, "signature"):
            artifacts.ipa(path, "org.example.app")

    @patch.dict(os.environ, {}, clear=True)
    def test_aab_upload_requires_manifest_tool(self):
        self.assertFalse(artifacts.aab(self.aab, "org.example.app")["manifest_verified"])
        with self.assertRaisesRegex(PublishingError, "BUNDLETOOL_JAR"):
            artifacts.aab(self.aab, "org.example.app", strict=True)

    @patch.dict(os.environ, {}, clear=True)
    def test_local_plans_do_not_authenticate(self):
        with patch.object(play, "token_provider", side_effect=AssertionError("unexpected auth")):
            result = play.execute(["plan", "--package-id", "org.example.app", "--artifact", str(self.aab)])
        self.assertEqual(result["external_requests"], 0)
        with patch.object(apple, "token_provider", side_effect=AssertionError("unexpected auth")):
            result = apple.execute(["plan", "--bundle-id", "org.example.app", "--app-id", "123", "--artifact", str(self.ipa)])
        self.assertEqual(result["external_requests"], 0)

    def test_play_authorization_precedes_auth_and_network(self):
        self.play_args.authorize_upload = False
        with self.assertRaisesRegex(PublishingError, "authorize"):
            play.publish(self.play_args, SequenceHTTP([]))

    def test_play_production_guard(self):
        self.play_args.track = "production"
        with self.assertRaisesRegex(PublishingError, "Production"):
            play.publish(self.play_args, SequenceHTTP([]))

    @patch.object(artifacts, "aab")
    def test_play_commit_and_retry_do_not_reupload(self, validate):
        validate.return_value = self.info
        http = SequenceHTTP([{"id": "edit-1"}, {}, {"bundles": []}, {"versionCode": 12, "sha256": "abc"},
                             {"releases": []}, {}, {"releases": [{"versionCodes": ["12"]}]}, {}, {"id": "edit-1"}])
        first = play.publish(self.play_args, http)
        self.assertEqual(first["status"], "commit_confirmed")
        self.assertEqual(first["publicly_live"], "unconfirmed")
        self.assertFalse(http.sequence)
        no_requests = SequenceHTTP([])
        self.assertEqual(play.publish(self.play_args, no_requests)["status"], "commit_confirmed")
        self.assertFalse(no_requests.calls)
        self.assertIn("ERROR_IF_IN_REVIEW", http.calls[-1][1])

    @patch.object(artifacts, "aab")
    def test_play_uncertain_commit_blocks_retry(self, validate):
        validate.return_value = self.info
        http = SequenceHTTP([{"id": "edit-1"}, {}, {"bundles": []}, {"versionCode": 12, "sha256": "abc"},
                             {"releases": []}, {}, {"releases": [{"versionCodes": ["12"]}]}, {}, PublishingError("timeout")])
        with self.assertRaises(PublishingError):
            play.publish(self.play_args, http)
        no_requests = SequenceHTTP([])
        with self.assertRaisesRegex(PublishingError, "outcome is unknown"):
            play.publish(self.play_args, no_requests)
        self.assertFalse(no_requests.calls)

    @patch.object(artifacts, "aab")
    def test_play_different_artifact_same_version_rejected(self, validate):
        validate.return_value = self.info
        http = SequenceHTTP([{"id": "edit-1"}, {}, {"bundles": [{"versionCode": 12, "sha256": "different"}]}])
        with self.assertRaisesRegex(PublishingError, "SHA256"):
            play.publish(self.play_args, http)
        self.assertFalse(any(call[3].get("media") for call in http.calls))

    @patch.object(artifacts, "aab")
    def test_play_staged_release_not_replaced(self, validate):
        validate.return_value = self.info
        http = SequenceHTTP([{"id": "edit-1"}, {}, {"bundles": [{"versionCode": 12, "sha256": "abc"}]},
                             {"releases": [{"status": "inProgress"}]}])
        with self.assertRaisesRegex(PublishingError, "staged/halted"):
            play.publish(self.play_args, http)
        self.assertFalse(any(call[0] == "PUT" for call in http.calls))

    def test_play_notes_and_metadata_limits(self):
        self.notes.write_text("x" * 501)
        with self.assertRaises(PublishingError):
            play.notes(self.notes, "en-US")
        path = self.root / "listing.json"
        path.write_text(json.dumps({"en-US": {"title": "x" * 31, "shortDescription": "text", "fullDescription": "text"}}))
        with self.assertRaises(PublishingError):
            play.metadata(path)

    def test_journal_identity_and_lock(self):
        path = self.root / "journal.json"
        with Journal(path, {"id": "one"}).locked() as journal:
            journal.save(phase="created")
            with self.assertRaisesRegex(PublishingError, "locked"):
                with Journal(path, {"id": "one"}).locked():
                    pass
        with self.assertRaisesRegex(PublishingError, "different"):
            with Journal(path, {"id": "two"}).locked():
                pass
        self.assertFalse(path.with_suffix(".json.lock").exists())

    def test_apple_wrong_app_rejected(self):
        http = SequenceHTTP([{"data": {"attributes": {"bundleId": "org.other.app"}}}])
        with self.assertRaisesRegex(PublishingError, "another bundle"):
            apple.upload(self.apple_args, http)

    def test_apple_duplicate_remote_build_rejected(self):
        http = SequenceHTTP([{"data": {"attributes": {"bundleId": "org.example.app"}}}, {"data": [{"id": "existing"}]}])
        with self.assertRaisesRegex(PublishingError, "already exists"):
            apple.upload(self.apple_args, http)

    def test_apple_upload_uses_current_command_and_secure_temp_key(self):
        key = self.root / "key.p8"
        key.write_text("offline fixture key")
        environment = {"ASC_KEY_ID": "KEYID", "ASC_ISSUER_ID": "issuer-id", "ASC_PRIVATE_KEY_PATH": str(key)}
        seen = []

        def execute(command, **kwargs):
            temp = Path(kwargs["env"]["API_PRIVATE_KEYS_DIR"])
            copied = temp / "AuthKey_KEYID.p8"
            self.assertEqual(copied.read_text(), "offline fixture key")
            self.assertEqual(copied.stat().st_mode & 0o777, 0o600)
            self.assertNotIn("offline fixture key", " ".join(command))
            seen.append((command, temp))
            return subprocess.CompletedProcess(command, 0)

        http = SequenceHTTP([{"data": {"attributes": {"bundleId": "org.example.app"}}}, {"data": []}])
        with patch.dict(os.environ, environment), patch.object(apple.subprocess, "run", side_effect=execute):
            result = apple.upload(self.apple_args, http)
        self.assertEqual(result["status"], "delivery_confirmed")
        self.assertEqual(result["testflight_available"], "unconfirmed")
        self.assertIn("--upload-package", seen[1][0])
        self.assertNotIn("--upload-app", seen[1][0])
        self.assertFalse(seen[1][1].exists())

    def test_apple_testflight_blocks_external_groups(self):
        http = SequenceHTTP([{"data": {"attributes": {"bundleId": "org.example.app"}}}, {"data": {"id": "123"}},
            {"data": {"attributes": {"processingState": "VALID"}}}, {"data": {"attributes": {"isInternalGroup": False}}}])
        with self.assertRaisesRegex(PublishingError, "internal TestFlight"):
            apple.distribute(self.apple_args, http)
        self.assertFalse(any(call[0] == "POST" for call in http.calls))

    def test_apple_group_assignment_confirms_separate_availability(self):
        http = SequenceHTTP([{"data": {"attributes": {"bundleId": "org.example.app"}}}, {"data": {"id": "123"}},
            {"data": {"attributes": {"processingState": "VALID"}}}, {"data": {"attributes": {"isInternalGroup": True}}},
            {"data": {"id": "123"}}, {"data": []}, {}, {"data": [{"id": "group-1"}]},
            {"data": {"attributes": {"internalBuildState": "READY_FOR_BETA_TESTING"}}}])
        result = apple.distribute(self.apple_args, http)
        self.assertEqual(result["status"], "group_assignment_confirmed")
        self.assertFalse(result["testflight_available"])

    def test_apple_keyword_limit_uses_bytes(self):
        path = self.root / "apple-metadata.json"
        path.write_text(json.dumps({"en-US": {"keywords": "é" * 51}}))
        with self.assertRaisesRegex(PublishingError, "UTF-8 bytes"):
            apple_metadata.metadata(path)

    def test_apple_jwt_real_es256_signature_and_lifetime(self):
        try:
            from cryptography.hazmat.primitives import hashes, serialization
            from cryptography.hazmat.primitives.asymmetric import ec, utils
        except ImportError:
            self.skipTest("Install automation/requirements.txt to verify ES256 signing")
        key = ec.generate_private_key(ec.SECP256R1())
        path = self.root / "generated-test-key.p8"
        path.write_bytes(key.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8,
                                           serialization.NoEncryption()))
        with patch.dict(os.environ, {"ASC_KEY_ID": "OFFLINE", "ASC_ISSUER_ID": "offline-issuer", "ASC_PRIVATE_KEY_PATH": str(path)}):
            provider = apple_auth.token_provider()
            token = provider()
            self.assertEqual(provider(), token)
        header, payload, signature = token.split(".")
        decode = lambda text: base64.urlsafe_b64decode(text + "=" * (-len(text) % 4))
        claims = json.loads(decode(payload))
        self.assertEqual(json.loads(decode(header))["alg"], "ES256")
        self.assertEqual(claims["exp"] - claims["iat"], 600)
        self.assertEqual(claims["aud"], "appstoreconnect-v1")
        raw = decode(signature)
        self.assertEqual(len(raw), 64)
        der = utils.encode_dss_signature(int.from_bytes(raw[:32], "big"), int.from_bytes(raw[32:], "big"))
        key.public_key().verify(der, (header + "." + payload).encode(), ec.ECDSA(hashes.SHA256()))

    def test_apple_metadata_authorization_precedes_network(self):
        with self.assertRaisesRegex(PublishingError, "authorize"):
            apple_metadata.apply(Namespace(authorize_write=False), SequenceHTTP([]))

    @patch("automation.publishing.common.urlopen", side_effect=URLError("sensitive upstream data"))
    def test_http_never_retries_writes_or_logs_upstream(self, open_url):
        with self.assertRaises(PublishingError) as context:
            HTTP(lambda: "secret").request("POST", "https://example.invalid", {})
        self.assertEqual(open_url.call_count, 1)
        self.assertNotIn("sensitive", str(context.exception))
        self.assertNotIn("secret", str(context.exception))

    @patch("automation.publishing.common.time.sleep")
    @patch("automation.publishing.common.urlopen")
    def test_http_retries_reads_with_bound(self, open_url, _sleep):
        open_url.side_effect = HTTPError("url", 503, "sensitive", {}, io.BytesIO(b"secret"))
        with self.assertRaisesRegex(PublishingError, "HTTP 503"):
            HTTP(lambda: "secret").request("GET", "https://example.invalid")
        self.assertEqual(open_url.call_count, 3)


if __name__ == "__main__":
    unittest.main()
